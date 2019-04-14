grammar Cal2;

@header{
    import java.util.*;
    import java.io.FileOutputStream;
    import java.io.FileWriter;
    import java.io.File;
}

@parser::members{

    String code = "";
    Integer indexCourant = 0;
    Integer cptLabel = 0;

    //gestion des etiquettes
    LinkedList<Integer> labelList = new LinkedList<Integer>();

    void ouvertureLabel(){
        code += "LABEL "+ cptLabel + "\n";
        labelList.addLast(cptLabel);
        cptLabel += 2;
    }

    void fermetureLabel(){

        code += "JUMP "+ labelList.getLast() + "\n";
        code += "LABEL "+ (labelList.getLast()+1) +"\n";

        labelList.removeLast();
    }

    void finIf(){
        code += "LABEL "+ (cptLabel) +"\n";
        cptLabel += 2;
    }

    //gestion des variables
    HashMap<String, Integer> mapIndex = new HashMap<String, Integer>();

    void ecritureFichier(){

        System.out.println("\nIndex : " + mapIndex);
        System.out.println("\n-------------EXECUTION DU MVAP CORRESPONDANT-------------\n");

        final String chemin = "./code.mvap";
        final File fichier = new File(chemin);

        try {
            fichier.createNewFile();
            // creation d'un writer
            final FileWriter writer = new FileWriter(fichier);
            try {
                writer.write(code + "HALT\n");
            } finally {
                // quoiqu'il arrive, on ferme le fichier
                writer.close();
            }
        } catch (Exception e) {
            System.out.println("Ecriture impossible");
        }
    }

    void analyseOperation(String op, String contexte){

        //choix de l'affichage dans le MVaP
        Integer affichage = -1;
        switch(contexte){
            case "boucle":
                affichage = labelList.getLast()+1;
                break;
            case "if":
                affichage = cptLabel;
                break;
        }

        switch(op){
            case "*":
                code += "MUL\n";
                break;
            case "/":
                code += "DIV\n";
                break;
            case "+":
                code += "ADD\n";
                break;
            case "-":
                code += "SUB\n";
                break;
            case "==":
                code += "EQUAL\n";
                code += "JUMPF " + affichage + "\n";
                break;
            case "!=":
                code += "NEQ\n";
                code += "JUMPF " + affichage + "\n";
                break;
            case "<":
                code += "INF\n";
                code += "JUMPF " + affichage + "\n";
                break;
            case "<=":
                code += "INFEQ\n";
                code += "JUMPF " + affichage + "\n";
                break;
            case ">":
                code += "SUP\n";
                code += "JUMPF " + affichage + "\n";
                break;
            case ">=":
                code += "SUPEQ\n";
                code += "JUMPF " + affichage + "\n";
                break;
            case "++":
                code += "ADD\n";
                break;
            case "--":
                code += "SUB\n";
                break;
        }
    }

    void lectureEntier(Integer a){
        code += "PUSHI " + a + '\n';
    }

    void lectureIdentifiant(String a){
        code += "PUSHG " + mapIndex.get(a) + "\n";
    }

    void affecter(String a){
        code += "STOREG " + mapIndex.get(a) + "\n";
    }

    void incrementer_decrementer(String a, String op){

        code += "PUSHG " + mapIndex.get(a) + "\n";
        code += "PUSHI 1\n";
        analyseOperation(op, "");
        code += "STOREG " + mapIndex.get(a) + "\n";
    }

    void declaration(String a){
        if(!mapIndex.containsKey(a)){
            code += "PUSHI 0\n";
            System.out.println("Declaration de " + a + " index = " + indexCourant);
            mapIndex.put(a,indexCourant);
            push();
        }
    }

    //affectation lors de la declaration
    void declaffecter(String a){
        if(!mapIndex.containsKey(a)){
            System.out.println("Declaration de " + a + " index = " + indexCourant);
            mapIndex.put(a,indexCourant);
            push();
        }
    }

    void traitementEntreeSortie(String fct, String a){
        switch(fct){
            case "println":
                code += "PUSHG " + mapIndex.get(a) + "\nWRITE\nPOP\n";
                break;
            case "readln":
                code += "READ\n" + "STOREG " + mapIndex.get(a) + "\n";
                break;
        }
    }

    void push(){
        indexCourant++;
    }
}

start
    : (instruction)* EOF{ecritureFichier();}
    ;

instruction
    : (decl|(affectation FININSTRUCTION)|declaffectation|boucle|exprSeule|regleIf|entreeSortie)
    ;

decl
    : TYPE IDENTIFIANT FININSTRUCTION
        {declaration($IDENTIFIANT.text);}
    ;

affectation
    : IDENTIFIANT '=' expr
        {affecter($IDENTIFIANT.text);}
    | IDENTIFIANT INCRDECR
        {incrementer_decrementer($IDENTIFIANT.text, $INCRDECR.text);}
    ;

declaffectation
    :TYPE IDENTIFIANT '=' expr FININSTRUCTION
        {declaffecter($IDENTIFIANT.text);}
    ;

boucle
    : boucleFor
    | boucleWhile
    ;

exprSeule
    //une expression isolée prends une place dans la pile
    : expr FININSTRUCTION? {push();}
    ;

regleIf
    : testIf (testElse)?
    ;

boucleWhile
    : motcleWhile corpsWhile
    ;

motcleWhile
    : 'while'
        {ouvertureLabel();}
    ;

corpsWhile
    : '(' condition ')' (bloc|instruction)
        {fermetureLabel();}
    ;

condition
    : expr COMP expr
        {analyseOperation($COMP.text, "boucle");}
    ;

bloc
    : '{' (instruction)+ '}'
    ;

boucleFor
    : motcleFor corpsFor
    ;

motcleFor
    : 'for' '(' affectation ';'
        {ouvertureLabel();}
    ;

corpsFor
    : condition ';' affectation ')' (bloc|instruction)
        {fermetureLabel();}
    ;

testIf
    : 'if' '(' condition ')' (bloc|instruction)
        {finIf();}
    ;

testElse
    : 'else' '{' (instruction)+ '}'
    | 'else' (affectation|boucle|exprSeule|regleIf)
    ;

expr
    : expr op=('*'|'/') expr
        {analyseOperation($op.text, "");}

    | expr op=('+'|'-') expr
        {analyseOperation($op.text, "");}

    | '(' expr ')'

    | ENTIER
        {lectureEntier($ENTIER.int);}

    | IDENTIFIANT
        {lectureIdentifiant($IDENTIFIANT.text);}
    ;

entreeSortie
    : fct=('println'|'readln') '(' IDENTIFIANT ')' FININSTRUCTION
        {traitementEntreeSortie($fct.text, $IDENTIFIANT.text);}
    ;

// lexer
FININSTRUCTION : ';' ;

COMMLIGNE : '//' ~('\r'|'\n')* ('\r'|'\n')* -> skip ;

COMMBLOC : '/*' .*? '*/' ('\r'|'\n')* -> skip ;

INCRDECR : ('++'|'--') ;

COMP : ('=='|'!='|'<'|'<='|'>'|'>=') ;

TYPE : 'int' | 'float' ;

IDENTIFIANT : (('a'..'z')|('A'..'Z'))+  ;

NEWLINE : '\r'? '\n' -> skip ;

WS :   (' '|'\t')+ -> skip  ;

ENTIER : ('-')? ('0'..'9')+  ;

UNMATCH : . -> skip ;
