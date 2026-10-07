"""Exercise backup and restore failure paths without a Docker daemon or AWS."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Operations(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        self.backups = self.directory / "backups"
        self.trace = self.directory / "trace"
        mock = '''#!/usr/bin/env python3
import json, os, pathlib, sys
with open(os.environ["TRACE"], "a") as f:
    f.write(json.dumps([pathlib.Path(sys.argv[0]).name] + sys.argv[1:]) + "\\n")
args = " ".join(sys.argv[1:])
if pathlib.Path(sys.argv[0]).name == "docker" and "pg_dump" in args:
    print("mock dump")
    sys.exit(int(os.getenv("DUMP_EXIT", "0")))
if "pg_restore" in args:
    sys.stdin.read()
    sys.exit(int(os.getenv("LIST_EXIT" if "--list" in args else "RESTORE_EXIT", "0")))
if pathlib.Path(sys.argv[0]).name == "aws":
    sys.exit(int(os.getenv("UPLOAD_EXIT", "0")))
'''
        for name in ("docker", "aws"):
            p = self.bin / name
            p.write_text(mock)
            p.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                        STACK_DIR=str(self.directory), BACKUP_DIR=str(self.backups),
                        BACKUP_S3_BUCKET="test-bucket", TRACE=str(self.trace))
        # A dotenv file is data, never a shell program (JVM options contain spaces).
        (self.directory / ".env").write_text("JAVA_OPTS=-Xmx1g -Xms256m\nexit 99\n")

    def run_script(self, name, *args, **env):
        return subprocess.run(["bash", str(ROOT / "scripts" / name), *args],
                              env=dict(self.env, **env), capture_output=True, text=True)

    def calls(self):
        return [json.loads(line) for line in self.trace.read_text().splitlines()]

    def test_backup_success_is_private_and_uploaded(self):
        result = self.run_script("backup.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        dump, = self.backups.glob("*.dump")
        self.assertEqual(dump.stat().st_mode & 0o777, 0o600)
        self.assertTrue((self.backups / ".last-success").exists())
        self.assertEqual(self.calls()[-1][0], "aws")

    def test_failed_dump_is_not_uploaded_or_retained(self):
        result = self.run_script("backup.sh", DUMP_EXIT="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(list(self.backups.glob("*.dump*")))
        self.assertFalse((self.backups / ".last-success").exists())
        self.assertTrue(all(call[0] != "aws" for call in self.calls()))

    def test_failed_upload_does_not_mark_success(self):
        result = self.run_script("backup.sh", UPLOAD_EXIT="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(list(self.backups.glob("*.dump"))), 1)
        self.assertFalse((self.backups / ".last-success").exists())

    def test_invalid_restore_does_not_stop_server(self):
        dump = self.directory / "input.dump"
        dump.write_text("invalid")
        result = self.run_script("restore.sh", str(dump), LIST_EXIT="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any("stop" in call for call in self.calls()))

    def test_failed_restore_leaves_server_stopped_and_indexes_untouched(self):
        dump = self.directory / "input.dump"
        dump.write_text("mock")
        result = self.run_script("restore.sh", str(dump), RESTORE_EXIT="1")
        self.assertNotEqual(result.returncode, 0)
        calls = self.calls()
        self.assertTrue(any("stop" in call for call in calls))
        self.assertFalse(any("start" in call or "run" in call for call in calls))

    def test_restore_clears_indexes_only_after_transaction(self):
        dump = self.directory / "input.dump"
        dump.write_text("mock")
        result = self.run_script("restore.sh", str(dump))
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        self.assertIn("--single-transaction", " ".join(calls[2]))
        self.assertIn("run", calls[3])
        self.assertIn("start", calls[4])


if __name__ == "__main__":
    unittest.main()
