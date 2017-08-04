/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRRegexLanguage.h"

@interface WRRegexLanguageASTBuilder : WRASTBuilder
@end

@implementation WRRegexLanguage
- (instancetype)init {
  if (self = [super
    initWithRuleStrings:@[
      @"S -> Frag",
      @"Frag -> Frag or Seq | Seq ",
      @"Seq -> Seq Unit | Unit ",
      @"Unit -> Single | Single PostOp | ( Frag ) ",
      @"PostOp -> + | * | ? ",
      @"Single -> char | charList ",
    ]
         andStartSymbol:@"S"]) {
    [self addVirtualTerminal:WRRELanguageVirtualConcatenate];
  }
  return self;
}

- (WRAST *)astNodeForToken:(WRToken *)token {
  WRRegexLanguageASTBuilder *builder =
    [[WRRegexLanguageASTBuilder alloc] initWithStartToken:token
                                                      andLanguage:self];
  [token accept:builder];
  return builder.ast;
}
@end


@implementation WRRegexLanguageASTBuilder

- (WRAST *)ast {
  return self.startToken.synAttr;
}

- (void)visit:(WRToken<WRVisiteeProtocol> *)token
 withChildren:(NSArray<WRToken<WRVisiteeProtocol> *> *)children {

  if (token == nil) {
    return;
  }
  if (token.type == WRTokenTypeTerminal) {
    // terminal
    // TODO
    assert(NO);
  } else {
    // nonterminal
    WRNonterminal *nonterminal = (WRNonterminal *) token;

    NSInteger tokenIndex = self.language.token2IdMapper[nonterminal.symbol].integerValue;
    switch (tokenIndex) {
      case 0: {
        // S -> Frag
        WRToken *frag = children[0];
        [frag accept:self];
        nonterminal.synAttr = frag.synAttr;
        break;
      }
      case 1: {
        switch (nonterminal.ruleIndex) {
          // Frag
          case 0: {
            // Frag -> Frag or Seq
            WRToken *frag = children[0];
            WRToken *or = children[1];
            WRToken *seq = children[2];
            [frag accept:self];
            [seq accept:self];
            WRAST *ast = [[WRAST alloc] initWithWRTerminal:or];
            [ast addChild:frag.synAttr];
            [ast addChild:seq.synAttr];
            nonterminal.synAttr = ast;
            break;
          }
          case 1: {
            // Frag -> Seq
            WRToken *seq = children[0];
            [seq accept:self];
            nonterminal.synAttr = seq.synAttr;
            break;
          }
          default:assert(NO);
        }
        break;
      }
      case 2: {
        // Seq
        switch (nonterminal.ruleIndex) {
          case 0: {
            // Seq -> Seq Unit
            WRToken *seq = children[0];
            WRToken *unit = children[1];
            WRTerminal *cat = [WRTerminal tokenWithSymbol:WRRELanguageVirtualConcatenate];
            cat.terminalType = tokenTypeCancatenate;
            
            [seq accept:self];
            [unit accept:self];
            WRAST *ast = [[WRAST alloc] initWithWRTerminal:cat];
            [ast addChild:seq.synAttr];
            [ast addChild:unit.synAttr];
            nonterminal.synAttr = ast;
            break;
          }
          case 1: {
            // Seq -> Unit
            WRToken *unit = children[0];
            [unit accept:self];
            nonterminal.synAttr = unit.synAttr;
            break;
          }
          default:assert(NO);
        }
        break;
      }
      case 3: {
        // Unit
        switch (nonterminal.ruleIndex) {
          case 0: {
            // Unit -> Single
            [children[0] accept:self];
            nonterminal.synAttr = children[0].synAttr;
            break;
          }
          case 1: {
            // Unit -> Single PostOp
            WRToken *single = children[0];
            WRToken *postOp = children[1];
            [single accept:self];
            [postOp accept:self];
            WRAST *ast = [[WRAST alloc] initWithWRTerminal:postOp.synAttr];
            [ast addChild:single.synAttr];
            nonterminal.synAttr = ast;
            break;
          }
          case 2: {
            // Unit -> ( Frag )
            WRToken *frag = children[1];
            [frag accept:self];
            nonterminal.synAttr = frag.synAttr;
            break;
          }
          default:assert(NO);
        }
        break;
      }
      case 4: {
        // PostOp -> + | * | ?
        WRTerminal *op = children[0];
        WRAST *ast = [[WRAST alloc] initWithWRTerminal:op];
        nonterminal.synAttr = ast;
        break;
      }
      case 5: {
        // Single -> char | charList
        WRTerminal *child = children[0];
        WRAST *ast = [[WRAST alloc] initWithWRTerminal:child];
        nonterminal.synAttr = ast;
        break;
      }
      default: {
        assert(NO);
      }
    }
  }
}

@end
