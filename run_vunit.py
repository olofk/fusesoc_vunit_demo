#
# vunit+FuseSoC launcher. fusesoc_vunit_demo
#
# Copyright (C) 2015  Olof Kindgren <olof.kindgren@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

from collections import OrderedDict
import os.path
from fusesoc.config import Config
from fusesoc.coremanager import CoreManager, DependencyError
from vunit import VUnitCLI, VUnit

cli = VUnitCLI()
cli.parser.add_argument('--core', nargs=1, required=True, help='Top-level FuseSoC core')
args = cli.parse_args()

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_args(args=args)

top_core = args.core[0]

#Create singleton instances for core manager and configuration handler
#Configuration manager is not needed in this example
cm = CoreManager()
#config = Config()

#Add core libraries that were picked up from fusesoc.conf by the config handler
#Not really necessary for this example as we can just add 'corelib' manually
try:
    #cm.add_cores_root(config.cores_root)
    cm.add_cores_root('corelib')
except (RuntimeError, IOError) as e:
    pr_warn("Failed to register cores root '{}'".format(str(e)))

#Get the sorted list of dependencies starting from the top-level core
try:
    cores = cm.get_depends(top_core)
except DependencyError as e:
    print("'{}' or any of its dependencies requires '{}', but this core was not found".format(top_core, e.value))
    exit(1)
#Hack 2. Disable for now. Should probably be hooked up to vunit_simulator
#CoreManager().tool = sim_name

#Iterate over cores, filesets and files and add all relevant sources files to vunit
incdirs = set()
src_files = []

#'usage' is a list of tags to look for in the filesets. Only look at filesets where any of these tags are present
usage = ['sim']
for core_name in cores:
    core = cm.get_core(core_name)
    core.setup()
    basepath = core.files_root
    for fs in core.file_sets:
        if (set(fs.usage) & set(usage)) and ((core_name == top_core) or not fs.private):
            for file in fs.file:
                if file.is_include_file:
                    #TODO: incdirs not used right now
                    incdirs.add(os.path.join(basepath, os.path.dirname(file.name)))
                else:
                    try:
                        vu.library(file.logical_name)
                    except KeyError:
                        vu.add_library(file.logical_name)
                    vu.add_source_file(os.path.join(basepath, file.name), file.logical_name)

# Run vunit function
vu.main()
