
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:barback/barback.dart';

import 'dart:async';

class ShaderLoader extends Transformer {
  ShaderLoader.asPlugin() {

  }

  Future<bool> isPrimary(AssetId id) async => id.extension == '.dart';

  Future apply(Transform transform) async {




    var content = await transform.primaryInput.readAsString();

    CompilationUnit c = parseCompilationUnit(content);

    c.accept(new MyAstVisitor());

    var id = transform.primaryInput.id;

    

    transform.addOutput(new Asset.fromString(id, c.toSource()));
  }
}

class MyAstVisitor extends RecursiveAstVisitor {
  @override
  void visitMethodInvocation(node) {
    if ('myLoadShader' == node.methodName.token.lexeme) {
      const String replacement = '"""FOOBAR"""';


      SimpleStringLiteral ssl = createSimpleStringLiteral(node,
                                                          replacement);

      node.parent.accept(new NodeReplacer(node, ssl));
    }
  }
}

SimpleStringLiteral createSimpleStringLiteral(AstNode node, String contents) {
  final StringToken st = new StringToken(
      TokenType.STRING, contents, node.offset);

  return new SimpleStringLiteral(st, contents);
}
