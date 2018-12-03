import json
import subprocess
import argparse
import os

VLOG_EXE="vlog -work work"
VSIM_EXE="vsim -c"

def get_tests():
    """ 
        Opens a JSON file containing just a list with the key tests
        It returns the list of test names
    """
    with open('tests.json') as test_suite:
        tests = json.load(test_suite)
    return tests["tests"]


def run_test(test_name):
    print(subprocess.check_output("{} {}".format(VSIM_EXE, test_name), shell=True))
    

def add_test(test_name):
    with open('tests.json', "r") as test_suite:
        tests = json.load(test_suite)
        tests["tests"].append(test_name)
        
    with open("tests.json", "w") as test_suite:
        json.dump(tests, test_suite)
    
    return 0

def compile_duts():
    files = os.listdir(".")
    files_to_compile = []
    for dut in files:
        if dut.lower().endswith((".sv", ".v")):
            files_to_compile.append(dut)
    
    args = " ".join(files_to_compile)
    print(subprocess.check_output("{} {}".format(VLOG_EXE, args), shell=True))


def main():
    tests = get_tests()
    print("===========BEGINNING TESTS==================")
    for test in tests:
        print("\n\n\nRUNNING {}".format(test))
        run_test(test)
        print("{} COMPLETED".format(test))
        
    print("===========TEST SUITE COMPLETED=============")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="The official, veri-good, test manager! Will get your Segway moving every time")
    parser.add_argument("-a", "--add_test", help="add a new test, e.g. -a test_1.sv")#, action="store_const")
    parser.add_argument("-c", "--compile", help="Compile all of the verilog and systemVerilog designs in the current directory",
            action="store_true")
    #parser.add_argument("-", "--", help="ADD ANOTHER OPTION HERE",
    #                action="store_true")
    args = parser.parse_args()
    if args.add_test is not None:
        add_test(args.add_test)
        print("TEST: {} ADDED SUCCESSFULLY".format(args.add_test))
    elif args.compile:
        compile_duts()
        print("COMPILE COMPLETED")
    else:
        main()

