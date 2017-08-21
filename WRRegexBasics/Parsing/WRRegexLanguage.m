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
  // TODO modify : delete single, use char instead
  if (self = [super
    initWithRuleStrings:@[
      @"S -> Expr",
      @"Expr -> Expr exOr SeqExpr | SeqExpr",
      @"SeqExpr -> SeqExpr exAnd UnitExpr | UnitExpr",
      @"UnitExpr -> exNot Frag | Frag",
      @"Frag -> Frag or Seq | Seq ",
      @"Seq -> Seq Unit | Unit ",
      @"Unit -> char | ( Frag ) | Unit PostOp ",
      @"PostOp -> + | * | ? ",
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
        // S -> Expr
        WRToken *expr = children[0];
        [expr accept:self];
        nonterminal.synAttr = expr.synAttr;
        break;
      }
      case 1: {
        // Expr
        switch (nonterminal.ruleIndex) {
          case 0: {
            // Expr -> Expr exOr SeqExpr
            WRToken *expr = children[0];
            WRToken *exOr = children[1];
            WRToken *seqExpr = children[2];
            [expr accept:self];
            [seqExpr accept:self];
            WRAST *ast = [[WRAST alloc] initWithWRTerminal:exOr];
            [ast addChild:expr.synAttr];
            [ast addChild:seqExpr.synAttr];
            nonterminal.synAttr = ast;
            break;
          }
          case 1: {
            // Expr -> SeqExpr
            WRToken *seqExpr = children[0];
            [seqExpr accept:self];
            nonterminal.synAttr = seqExpr.synAttr;
            break;
          }
          default:assert(NO);
        }
        break;
      }
      case 2: {
        // SeqExpr
        switch (nonterminal.ruleIndex) {
          case 0: {
            // SeqExpr -> SeqExpr exAnd UnitExpr
            WRToken *seqExpr = children[0];
            WRToken *exAnd = children[1];
            WRToken *unitExpr = children[2];
            [seqExpr accept:self];
            [unitExpr accept:self];
            WRAST *ast = [[WRAST alloc] initWithWRTerminal:exAnd];
            [ast addChild:seqExpr.synAttr];
            [ast addChild:unitExpr.synAttr];
            nonterminal.synAttr = ast;
            break;
          }
          case 1: {
            // SeqExpr -> UnitExpr
            WRToken *unitExpr = children[0];
            [unitExpr accept:self];
            nonterminal.synAttr = unitExpr.synAttr;
            break;
          }
          default:assert(NO);
        }
        break;
      }
      case 3: {
        // UnitExpr
        switch (nonterminal.ruleIndex) {
          case 0: {
            // UnitExpr -> exNot Frag
            WRToken *exNot = children[0];
            WRToken *frag = children[1];
            [frag accept:self];
            nonterminal.synAttr = frag.synAttr;
            break;
          }
          case 1: {
            // UnitExpr -> Frag
            WRToken *frag = children[0];
            [frag accept:self];
            nonterminal.synAttr = frag.synAttr;
            break;
          }
          default:assert(NO);
        }
        break;
      }
      case 4: {
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
      case 5: {
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
      case 6: {
        // Unit
        switch (nonterminal.ruleIndex) {
          case 0: {
            // Unit -> char
            nonterminal.synAttr = [[WRAST alloc] initWithWRTerminal:children[0]];
            break;
          }
          case 1: {
            // Unit -> ( Frag )
            WRToken *frag = children[1];
            [frag accept:self];
            nonterminal.synAttr = frag.synAttr;
            break;
          }
          case 2: {
            // Unit -> Unit PostOp
            WRToken *unit = children[0];
            WRToken *postOp = children[1];
            [unit accept:self];
            [postOp accept:self];
            WRAST *ast = postOp.synAttr;
            [ast addChild:unit.synAttr];
            nonterminal.synAttr = ast;
            break;
          }
          default:assert(NO);
        }
        break;
      }
      case 7: {
        // PostOp -> + | * | ?
        WRTerminal *op = children[0];
        WRAST *ast = [[WRAST alloc] initWithWRTerminal:op];
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
