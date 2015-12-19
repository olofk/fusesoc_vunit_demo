# fusesoc_vunit_demo
Demo project for FuseSoC + VUnit integration

Run `python run_vunit.py -o packet_generator` to start the test.

Some notes:

1. VUnit output directory must be set to the name of the top-level FuseSoC core. The demo project uses `packet_generator` as top-level, which is why `-o packet_generator` is added to the arguments

2. Make sure to have VUnit and FuseSoC in your Python PATH, or run with `PYTHONPATH=/path/to/vunit:/path/to/fusesoc run_vunit.py -o packet_generator`

3. This requires having one of the VUnit-compatible simulators in your $PATH. This is described in more detail on the vunit page.
