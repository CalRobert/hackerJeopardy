import csv


questions = []
answers = []


with open("jeopardy1.csv", 'r') as csvfile:
  csvreader = csv.reader(csvfile)

  questcount = 0
  answercount = 0
  for n,row in enumerate(csvreader):
    if n % 2 == 0 and n < 12 and n > 0:
      answers.append(row)
      answercount+= 1
      
    if n % 2 == 1 and n < 12 and n > 0:
      questions.append(row)
      questcount+=1

globindex = 1

# Start at one because first is the amount
for a in range(1,7):
  for q in range(0,5):
    
    value = q + 1 #1 for $100, 4 for $400, etc.

    thisQuestion = questions[q][a].ljust(140)
    thisAnswer = answers[q][a].ljust(64)

    # Brute force way to get rid of non-ascii chars
    thisQuestion = ''.join([x for x in thisQuestion if ord(x) < 128])
    thisAnswer = ''.join([x for x in thisAnswer if ord(x) < 128])
    
    
    thisQuestion = thisQuestion.ljust(140)
    thisAnswer = thisAnswer.ljust(64)
    



    print("""    %s: 'Cat %s $%s00 question
        questVal := %s
        bytemove(@Question, string("%s"),140)
        bytemove(@Answer,   string("%s"),64)""" % (globindex, a , value, value * 100, thisQuestion, thisAnswer ))
    

    globindex += 1

