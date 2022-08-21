
# The % symbol in Python is called the Modulo Operator



# Write a Python program to find those numbers which are divisible by 7 
# and multiple of 5, between 1 and 100 (both included)


for i in range(1,100):

    if i%7==0 and i%5==0:

        print("  ",i)



# Write a Python program to count the number of even and 
# odd numbers from the following series of numbers  [1, 2, 3, 4, 5, 6, 7, 8, 9]

l = [1,2,3,4,5,6,7,8,9] 

even, odd= 0, 0

for i in l: 

    if i % 2 == 0: 

        even += 1

    else: 

        odd+= 1          

print("Even : ", even) 

print("Odd : ", odd)


# Write a Python program that prints all the numbers from 0 to 6 except 3 and 6.

for x in range(6):
    if (x == 3 or x==6):
        continue
    print(x,end=' ')
print("\n")


# Write a Python program that iterates the integers from 1 to 50. For multiples of three print "Fizz" instead of the number 
# and for the multiples of five print "Buzz".
# For numbers that are multiples of both three and five print "FizzBuzz"


for num in range(1,50):
    if num % 3 == 0 and num % 5 == 0:
        print("FizzBuzz: "+str(num))
    elif num % 3 == 0:
        print("Fizz:" +str(num))
    elif num % 5 == 0:
        print("Buzz:" +str(num))
    else:
        print(num)


