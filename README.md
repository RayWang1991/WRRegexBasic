# WRRegexbasic: A Powerful Pure Regex Engine
## 0 Features
1. **DFA to regex**
2. **Regex intersection, union, negation operation**
3. **DFA compression**
4. **Epsilon free NFA conversion**
5. **Using range to represent transitions**
## 1 How to install
**Clone this repo and build it in Xcode**
## 2 How to use
the basic work flow is like this:
```
- (BOOL)workFlowWithRegex:(NSString *)regex
                 andInput:(NSString *)input{
  // Parsing For Regex, you can cache the parser and scanner if needed
  WRLR1Parser *parser = [[WRLR1Parser alloc] init];
  WRLanguage *language = [[WRRegexLanguage alloc] init]; 
  WRRegexScanner *scanner = [[WRRegexScanner alloc] init];
  parser.language = language;
  parser.scanner = scanner;
  [parser prepare];
  scanner.inputStr = regex; 
  [parser startParsing];
  WRAST *ast = [language astNodeForToken:parser.parseTree];

  // build dfa for regex
  WRCharRangeNormalizeMapper *mapper = [[WRCharRangeNormalizeMapper alloc] initWithRanges:scanner.ranges];
  
  for (WRCharTerminal *charTerminal in scanner.charTerminals) {
    charTerminal.rangeIndexes = [mapper decomposeRangeList:charTerminal.ranges];
  };

  WRREFAManager *manager = [[WRREFAManager alloc] initWithCharRangeMapper:mapper
                                                                      ast:ast];

  WRREFABuilder *builder = manager.builder;

  // [builder printDFA]; print the state

  // [builder DFA2Regex]; if you have dfa states, you can transfer it to regex

  // you can use the regex to match multiple inputs

  return [builder matchWithString:input];
}
```
you can use this lib to wrap your own regex functions, cache the parser, scanner, dfaManager if needed.
For more examples, plz see section 4 and examples in testcases.
## 3 Grammars
### post operators
- clojure operator : *  
  e.g. 1* // zero or more char '1'
- plus operator : +  
  e.g. 1+ // one or more char '1' 
- question operator : ?  
  e.g. 1? // zero or one char '1'

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
- concatenate operator : (virtual operator) // when a expression(expr2) is right after another one(expr1), we have a new expression expr formed by expr1 concatenated by expr2  
  e.g. 12 // new expression that is concatenation of expression "1" and expression "2"

### char representations
- single char :any single ASCII char except the former sepecial ones  
  e.g. 1, 2, a, _, !, %,  , &

- escaped char:
  1. represent the char that sepecail operators use  
  e.g. /? // char '?'  
  e.g. /( // char '('  
  e.g. // // char '/'
  2. a short notion for ragne  
  e.g. /d //all single digits, from '0' to '9'  
  e.g. /w //'0' to '9', 'a' to 'z', 'A' to 'Z'  
  e.g. /a //'a' to 'z',  
  e.g. /A //A' to 'Z'
  3. others  
  e.g. /t(*tab*), /n((*new line*), /r(*carriage return*)

- char range :  
  1. a pair of brackets with characters inside  
  e.g. \[abcde\] //a|b|c|d|e  
  e.g. \[!.+\](*\!|\.|\+* **notice that special operators here are treated as characters**)
  1. a pair of brackets with character-character patterns  
  e.g. \[a-e\] //a|b|c|d|e,   
  e.g. \[a-c0-4] //a|b|c|d|0|1|2|3|4
  **this style is preffered, and some optimizations are done for it**

### others
- any: . //represent any single char in range  
  e.g. .. //match any string at length of 2
- parentheses: () //raise the priority of the expression to the highest  
  e.g. (1|2)* //zero or more alternation of char '1' and char '2'

### operator precedence
  () > \* = + = ? > concatenate > | > \\! > \& > \\|
## 4 Examples for Regex
```
"1" //  a single char '1'
"1*1+1?" // zero or more '1' followed by one or more '1' followed by zero or one '1'
"\!1" // negation of '1'
".*111.*\&\!.*00.*" // intersection of regex1: any string contains "111", and regex2: any string does not contain "00"
"(0|1)*111[01]*\&\![01]*00[01]*" // regex of "(0|1)*111[01]* "intersects with the negation of "[01]*00[01]*"
```

