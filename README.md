Lunarcows
---------

The classic "bulls and cows" game implementation in Lua. You have 20 tries to guess
a randomly generated number of 4 different digits while the computer opponent is
trying to reveal your number.

Currently two types of computer opponents are available.

- Stupid - just tries random numbers.
- Smarter - create a list of all possible numbers and try a random
  one. Than mark all numbers that would lead to different result on
  first turn as impossible and try a randomly selected one or remained.
  Than mark all numbers that would lead to different outcome on the
  second turn as impossible and so on.

Created just for my first experience with Lua.

