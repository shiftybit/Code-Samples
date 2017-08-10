# GUI for Checking Out Loaner Devices (Will Integrate into InventoryDatabaseUpdate.py once I get it working) 

# Input Fields: Tech, User, Dept, Reason

import clr
import tkinter as tk
from tkinter import *
from tkinter.messagebox import showinfo
clr.AddReference('System.Data')
from System.Data.SqlClient import SqlConnection, SqlCommand
from System import InvalidOperationException
import random
import ipdb

ITS12163DGString = "Data Source=its12163dg,1433;Integrated Security=SSPI;Database=Inventory;"
connection = SqlConnection(ITS12163DGString)

root = Tk()
root.title('Loaner Laptop Sign Out')
root["background"] = "cyan"
tex = Text(root, height=5, width = 100)
root.minsize(20,20)

def tprint(string):
	tex.insert(INSERT,"%s \r\n" % string)
	tex.see(END)
print=tprint


def SignOutLoaner (loaner, tech, user, department, reason):
	global addmode
	try:
		connection.Open()
	except InvalidOperationException as er:
		print("Exception Caught - Reopening SQL Connection")
		connection.Close()
		connection.Open()
	except Exception as er: 
		print("connection.Open Exception %s" % type(er).__name__)
	SQLstring = "INSERT INTO dbo.LoanerSignOuts VALUES (CURRENT_TIMESTAMP, %s, %s, %s, %s, %s, null)" % (loaner, tech, user, department, reason)
	ipdb.set_trace()
	command = SqlCommand(SQLstring, connection)
	subt = command.ExecuteReader()
	subt.Close()
	
	print("%s checkout was successful." % loaner)
		
	connection.Close()
	entry.delete(0,END)
	entry2.delete(0,END)
	
def cbc(thing1):
	try:
		tech='Kayla' #str(entry.get())
		user= 'Christy' #str(entry2.get())
		department= 'ITS' #str(entry3.get())
		reason= 'Test' #str(entry4.get())
		loaner = 'ITSLoaner1'
	except ValueError as er:
		print("Something Went Wrong. Restart the program and if that does not work talk to Kayla.")
		return
	SignOutLoaner(loaner, tech, user, department, reason)

myContainer1 = Frame(root)
myContainer2 = Frame(root)
myContainer3 = Frame(root)
myContainer4 = Frame(root)

label1=Label(myContainer1, text='Technician:               ', bg='cyan', font=2)
label2=Label(myContainer2, text='User:                         ', bg='cyan', font=2)
label3=Label(myContainer3, text='Department:            ', bg='cyan', font=2)
label4=Label(myContainer4, text='Reason for Loaner:', bg='cyan', font=2)
label1.pack(side = LEFT)
label2.pack(side = LEFT)
label3.pack(side = LEFT)
label4.pack(side = LEFT)

entry = Entry(myContainer1, width=70)
entry2 = Entry(myContainer2, width=70)
entry3 = Entry(myContainer3, width=70)
entry4 = Entry(myContainer4, width=70)
entry.pack(side=LEFT)
entry2.pack(side=LEFT)
entry3.pack(side=LEFT)
entry4.pack(side=LEFT)

myContainer1.pack()
myContainer2.pack()
myContainer3.pack()
myContainer4.pack()
tex.pack(side=BOTTOM)

button1 = Button(root, text='Submit')
button1.bind("<Button-1>", cbc)
button1.bind("<Return>", cbc)

button1.pack(side=BOTTOM)

def PopTart():
	print('Last Updated 7/28/17 4:00 PM by kayla.kindred')
root.after(500,PopTart)

root.mainloop()