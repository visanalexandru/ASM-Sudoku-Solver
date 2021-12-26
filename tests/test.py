import subprocess

def to_grid(s):
    column=0
    result=""
    for x in s:
        result+=str(x)+" "
        column+=1
        if column==9:
            result+='\n'
            column=0
    return result

def output_to_file(string,filename):
    with open(filename,"w") as f:
        f.write(string)

def read_file(filename):
    return open(filename,"r").read().strip()

def test():
    with open("sudoku.csv","r") as f:
        f.readline() # Skip over the first line 
        test=0

        for line in f:
            tokens=line.split(",")

            quiz=to_grid(tokens[0]).strip()
            solution=to_grid(tokens[1]).strip()

            output_to_file(quiz,"input")
            subprocess.run(["./sudoku","input","output"])
            output=read_file("output")
            
            if solution!=output:
                print(f"Test {test} failed")
                print(f"Input:\n{quiz}")
                print(f"Output:\n{output}")
                print(f"Solution:\n{solution}")
                break

            else:
                print(f"Ok test {test}")
            test+=1


test()

