# WRRegexbasic: A Powerful Pure Regex Engine
## 0 Features
## 1 How to install
## 2 How to use
## 3 Grammars
### post operators
clojure operator : *
  e.g. (expr)* // zero or more expr(s)
plus operator : + 
  e.g. (expr)+ // one or more expr(s)
question operator : "?"
  e.g. (expr)? // zero or one expr

### set operators
negetion operator : /!
  e.g. /!1 // new expresssion that is the negation of expr "1"
intersection operator : /&
  e.g. 1/&2 // new expresssion that is formed by expr "1" intersects with expr "2"
union operator : |/
  e.g. 1/|2 // new expresssion that is formed by expr "1" unions with expr "2"

### expression operators
alternate operator : |
  e.g. /!1 // new expresssion that is the negation of "1"
intersection operator : /&
  e.g. 1/&2 // new expresssion that is formed by expr "1" intersects with expr "2"
union operator : |/
  e.g. 1/|2 // new expresssion that is formed by expr "1" unions with expr "2"

char : 
  1. any single ASCII char except the former sepecial ones 
  e.g. 1, 2, a, _, !, %,  , &
  2. excaped char (except the expression operators)
  e.g. "/1" (still means "1"), "/d" (all single digits, from "0" to "9"), "/w"
  
### virtual operator
concatenate operator : when a expression(expr2) is right after another one(expr1), we have a new expression expr formed by expr1 concatenated by expr2
  e.g.
  
### operator level
  * = + = ? > (cat)
## 4 Examples


