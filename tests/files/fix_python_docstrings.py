import os


class ClassA(object):
    def method_a():
        print("Hello")

    def method_b():

        print("Hello")

    def method_c(string):
        print(string)
    
    def method_d(string: str):
        print(string)
    
    def method_e(string: str="Hello"):
        print(string)

    def method_f(string: str="Hello") -> str:
        print(string)

    def method_g(token: str):
        access_token = token

