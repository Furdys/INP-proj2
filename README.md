# Simple 8-bit CPU - BrainLove interpreter (INP project 2)
Bachelor study at FIT VUT Brno  
3rd semester - winter 2017  
Subject: **Design of Computer Systems (INP)**

## Score
* Overall: **18/23**
* CPU implementation: **12/17**

## Tests
| Code | Result |
| ------ | ------ |
| ++++++++++ | ok |
| ---------- | ok |
| +>+\+>+++ | ok |
| <+<+\+<+++ | ok |
| .+.+.+. | ok |
| ,+,+,+, | ok |
| [........]noLCD[.........] | ok |
| +++[.-] | ok |
| +++++[>++[>+.<-]<-] | error |
| +[+~------------]+ | ok |
| +[+~[-----]-----]+ | ok |
* Simple loop support: yes
* Nested loop support: no

## Commentary
* Incomplete sensitivity list; missing signals: RESET, pcVal
* Possible problems with signals: DATA_RDWR, DATA_WDATA, OUT_DATA, instruction, pcValLoopStart