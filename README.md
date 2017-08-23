# WRRegexbasic: A Powerful Pure Regex Engine
## 0 Features
## 1 How to install
## 2 How to use
## 3 Grammars
### post operators
- clojure operator : *  
  e.g. (expr)* // zero or more expr(s)
- plus operator : +  
  e.g. (expr)+ // one or more expr(s)
- question operator : "?"  
  e.g. (expr)? // zero or one expr

### set operators
- negetion operator : /!  
  e.g. /!1 // the negation of expression "1"
- intersection operator : /&  
  e.g. 1/&2 // the intersection of expression "1" and expression "2"
- union operator : /|  
  e.g. 1/|2 // the union of expression "1" and expression "2"

### expression operators
- alternate operator : |  
  e.g. 1|2 // new expresssion that is the alternate of expression "1" and expression "2"
- concatenate operator : (virtual operator) when a expression(expr2) is right after another one(expr1), we have a new expression expr formed by expr1 concatenated by expr2  
  e.g. 12 // new expression that is concatenation of expression "1" and expression "2"

### char representations
- single char :any single ASCII char except the former sepecial ones  
  e.g. 1, 2, a, _, !, %,  , &

- escaped char:
  1. represent the char that sepecail operators use  
  e.g. /?(*char '?'*), /((*char '('*), //(*char '/'*)
  2. (a short notion for ragne)  
  e.g. /d (*all single digits, from '0' to '9'*), /w (*'0' to '9', 'a' to 'z', 'A' to 'Z'*), /a (*'a' to 'z'*), /A(*'A' to 'Z'*)
  3. others  
  e.g. /t(*tab*), /n((*new line*), /r(*carriage return*)

- char range :  
  1. a pair of brackets with characters inside  
  e.g. \[abcde\](*a|b|c|d|e*), \[!.+\](*\!|\.|\+* **notice that special operators here are treated as characters**)
  1. a pair of brackets with character-character patterns  
  e.g. \[a-e\](*a|b|c|d|e*), \[a-c0-4](*a|b|c|d|0|1|2|3|4*)  
  //** this style is preffered, and some optimizations are done for it**

### virtual operator
  e.g.
  
### operator level
  * = + = ? > (cat)
## 4 Examples


