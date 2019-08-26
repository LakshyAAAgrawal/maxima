| <img src="https://upload.wikimedia.org/wikipedia/commons/1/1e/GSoC.png" href="https://summerofcode.withgoogle.com" title="Google Summer of Code 2019" width="156" height="156" /> | <img title="INCF" href="https://www.incf.org/"  src="http://nprc.incf.org/wp-content/uploads/2016/10/INCF-short-logo-pantone-1.png" width="278" height="156" /> | <img title="Maxima" href="http://maxima.sourceforge.net/" src="https://upload.wikimedia.org/wikipedia/commons/4/4a/Maxima-new.svg" width="156" height="156" /> |  
|:--:|:--:|:--:|
## Pytranslate - Maxima to Python Translator
### Introduction

Package pytranslate, introduced through [merge #15](https://sourceforge.net/p/maxima/code/merge-requests/15/) as a loadable package in [Maxima](http://maxima.sourceforge.net/) and [#17](https://sourceforge.net/p/maxima/code/merge-requests/17/) provides Maxima to Python translation functionality. It was developed under the mentorship of Dimiter Prodanov and Rober Dodier as an [INCF](https://www.incf.org/activities/training/google-summer-of-code) project during Google Summer of Code 2019 by Lakshya A Agrawal of Indraprastha Institute of Information Technology, Delhi, India. 

Python has extensive library support and gaining a stronghold in the field of neuroinformatics. Maxima is an expressible computer algebra system and language. A Maxima to Python Translator will provide a way for implementation of algorithms in Maxima which make use of the extensive libraries in Python. One can write certain parts of algorithms in Maxima and others in Python, and ultimately translate Maxima to Python, integrating both. Further, for a person comfortable in Maxima, it will be easy to share their work with a person unfamiliar with Maxima. 

The project proposal for Google Summer of Code is available [here](https://drive.google.com/file/d/1s3HqiopV8VWaO8s2X2F5JcJAsnMsN8mT/view?usp=sharing).

Pytranslate is written in Common Lisp and Maxima. The source code is present in the [Maxima repository](https://sourceforge.net/p/maxima/code/ci/master/tree/share/pytranslate/).

### Usage
Pytranslate can be loaded in a Maxima instance for use, by executing ```load(pytranslate);```
The statements are converted to python3 syntax. The file [share/pytranslate/pytranslate.py](https://sourceforge.net/u/philomath/maxima_translate/ci/304a298d768f20c9e1761cc8ca35445c40ebbaff/tree/share/pytranslate/pytranslate.py) must be imported as ``` from pytranslate import *``` for all translations to run, as shown in the example below.

![Example run](https://i.imgur.com/PWlHnWY.gif)

Example:  
In maxima:
```lisp
(%i1) load (pytranslate)$
```
```c
/* Define an example function in Maxima to calculate square, and call pytranslate */
(%i1) pytranslate(sqr(x):=x^2); 
(%o1) 
/* Translated python3 code */
def sqr(x, v = v):
    v = Stack({}, v)
    v.ins({"x" : x})
    return(f["pow"](v["x"], 2))
f["sqr"] = sqr

(%i3) sqr(5);
(%o3) 25
```
In python3:
```python
>>> from pytranslate import *
>>> def sqr(x, v = v):
...     v = Stack({}, v)
...     v.ins({"x" : x})
...     return(f["pow"](v["x"], 2))
... 
>>> sqr(5)
25.0
```
Plotting example:  
In maxima:
```lisp
(%i1) pytranslate('(plot3d(lambda([x, y], sqrt(2-x^2 -y^2)), [x, -1, 1], [y, -1, 1])));
(%o1) f["plot3d"](lambda x, y, v = Stack({}, v): math.sqrt((2 + 
							   (-f["pow"](x, 2)) + 
						           (-f["pow"](y, 2)))), ["x", -1, 1], ["y", -1, 1])
```
Generated Plot:  

| ![3D Plot](https://i.imgur.com/x3HkW7A.png) | 
|:--:| 
| *(Left - Maxima), (Right - Python)* |
| ![2D Plots](https://i.imgur.com/YzKIzbK.gif) |
| *Example 2D Plots - mwright and cantor functions* |

### Supported Maxima forms
1. Numbers(including complex numbers)
1. Assignment operators(:, :=)
1. Arithmetic operators(+, -, , ^, /, !)
1. Logical operators(and, or, not)
1.    Relational operators(>, <, >=, <=, !=, =)
1.    Lists, endcons
1.    Arrays
1.    block(mprog) and mprogn
1.    Function and function calls
1.    if-else form
1.    Loops(do, while, unless, for, from, thru, step, next, in)
1.    lambda form
1.    Plots(2D and 3D) using matplotlib, numpy
1.    Integration using Quadpack(mpmath), demonstrated on quadqagi

### Files in pytranslate
* [share/pytranslate/pytranslate.lisp](https://sourceforge.net/u/philomath/maxima_translate/ci/304a298d768f20c9e1761cc8ca35445c40ebbaff/tree/share/pytranslate/pytranslate.lisp) - contains all the translation procedures and working logic of pytranslate.  
  Introduced as transpiler.lisp in commit [[764b7a]](https://sourceforge.net/u/philomath/maxima_translate/ci/764b7a8aa8737399c404e6c7a1191b93d62abbe2/).  
  Renamed to pytranslate.lisp in commit [[9481a9]](https://sourceforge.net/u/philomath/maxima_translate/ci/9481a98bd817aa43d5ed3d5ca670dae1af4ebf53/)
  
* [share/pytranslate/rtest_pytranslate.mac](https://sourceforge.net/u/philomath/maxima_translate/ci/304a298d768f20c9e1761cc8ca35445c40ebbaff/tree/share/pytranslate/rtest_pytranslate.mac) - contains the tests for pytranslate. Among many others, the tests include example functions to generate continued fraction representation of a given number, generate the number from it's continued fraction representation, and cantor function.  
  Introduced in commit [[25f90b]](https://sourceforge.net/u/philomath/maxima_translate/ci/25f90b7f1d99bf68782642d7125c9d15878bf69e/)
  
* [doc/info/pytranslate.texi](https://sourceforge.net/u/philomath/maxima_translate/ci/304a298d768f20c9e1761cc8ca35445c40ebbaff/tree/doc/info/pytranslate.texi) - contains the documentation for pytranslate usage, working, and method to extend pytranslate.  
  Introduced in commit [[acef78]](https://sourceforge.net/u/philomath/maxima_translate/ci/acef78d97760a0542279c75b627c628b574764df/)
  
* [share/pytranslate/pytranslate.py](https://sourceforge.net/u/philomath/maxima_translate/ci/304a298d768f20c9e1761cc8ca35445c40ebbaff/tree/share/pytranslate/pytranslate.py) - All translated code requires the import of pytranslate.py, which defines several function and variable maps from Maxima to Python. It defines Stack, and variables v and f which are used to hold variable bindings in translated code per scoping rules in Maxima.  
  Introduced in commit [[f38107]](https://sourceforge.net/u/philomath/maxima_translate/ci/f3810765e5f880ca3ef77de66a6906b2cb51bfd4/)
  
* [share/pytranslate/cantorr.py](https://sourceforge.net/u/philomath/maxima_translate/ci/304a298d768f20c9e1761cc8ca35445c40ebbaff/tree/share/pytranslate/cantorr.py) - Example translated file - All functions are translated from Maxima containing algorithmic and plotting code.  
  Introduced in commit [[67a246]](https://sourceforge.net/u/philomath/maxima_translate/ci/67a24606547b1b5954253ff582381a33bcfac7ee/).

### Tests for pytranslate

The tests for pytranslate are present at [share/pytranslate/rtest_pytranslate.mac](https://sourceforge.net/u/philomath/maxima_translate/ci/304a298d768f20c9e1761cc8ca35445c40ebbaff/tree/share/pytranslate/rtest_pytranslate.mac) and can be evaluated by executing ```batch(rtest_pytranslate, test);```

### Functions in pytranslate

Function: **pytranslate (expr, [print-ir])**

Translates the expression expr to equivalent python3 statements. Output is printed in the stdout.

Example:
```lisp
(%i1) pytranslate('(for i:8 step -1 unless i<3 do (print(i))));
```
```python
(%o1) 
v["i"] = 8
while not((v["i"] < 3)):
    m["print"](v["i"])
    v["i"] = (v["i"] + -1)
del v["i"]
```
expr is evaluated, and the return value is used for translation. Hence, for statements like assignment, it might be useful to quote the statement:
```lisp
(%i2) pytranslate(x:20);
(%o2) 
20
```
```lisp
(%i3) pytranslate('(x:20));
(%o3) 
v["x"] = 20
```
Passing the optional parameter (print-ir) to pytranslate as t, will print the internal IR representation of expr and return the translated python3 code.
```lisp
(%i2) pytranslate( '(plot3d(lambda([x, y], x^2 + y^(-1)), [x, 1, 10], [y, 1, 10])), t);
```
```lisp
/* Generated IR */
(body
 (funcall (element-array "m" (string "plot3d"))
  (lambda ((symbol "x")
                       (symbol "y")
                        (op-no-bracket = (symbol "v") (funcall (symbol "stack") (dictionary) (symbol "v"))))
   (op + (funcall (element-array (symbol "m") (string "pow")) (symbol "x") (num 2 0))
               (funcall (element-array (symbol "m") (string "pow")) (symbol "y") (unary-op - (num 1 0)))))
  (struct-list (string "x") (num 1 0) (num 10 0))
  (struct-list (string "y") (num 1 0) (num 10 0)))) 
```
```
(%o2) 
f["plot3d"](lambda x, y, v = Stack({}, v): (f["pow"](x, 2) + f["pow"](y, (-1))), ["x", 1, 10], ["y", 1, 10])
```
Function: **show_form (expr)**

Displays the internal maxima representation of expr.

Example:
```lisp
(%i4) show_form(a^b);
((mexpt) $a $b) 
(%o4) a^b
```

### Working of pytranslate
* The entry point for pytranslate is the function ```$pytranslate``` defined in [share/pytranslate/pytranslate.lisp](https://sourceforge.net/u/philomath/maxima_translate/ci/304a298d768f20c9e1761cc8ca35445c40ebbaff/tree/share/pytranslate/pytranslate.lisp).
* *$pytranslate* calls the function ```maxima-to-ir``` with the Maxima expression as an argument(henceforth referred to as *expr*).
* ```maxima-to-ir``` determines if *expr* is atomic or non-atomic(lisp cons form). If atomic, ```atom-to-ir``` is called with *expr*, which returns the IR for the atomic expression.
* If *expr* is non-atomic, the function ```cons-to-ir``` is called with *expr* as an argument.
    * ```cons-to-ir``` looks for ```(caar expr)```, which specifies the type of *expr*(like addition operator, function call, etc.), in hash-table \**maxima-direct-ir-map*\*. If the type is found, then it appends the IR retrieved from hash-table with the result of lisp call ```(mapcar #'maxima-to-ir (cdr expr))```, which applies *maxima-to-ir*&nbsp; function to all the elements present in *expr*. Effectively, it recursively generates the IR form for all the elements present in *expr* and appends them to the IR map for the type.  
      Example:

      ```  
      (%i9) show_form(a+b);
      ((mplus) $b $a)
      ```  
      ```lisp  
      (%i10) pytranslate(a+b, t);
      (body (op + (element-array (symbol "v") (string "b")) (element-array (symbol "v") (string "a"))))
      (%o10) 
      (v["b"] + v["a"])
      ```

      Here, operator + with internal maxima representation - ```(mplus)``` is present in \**maxima-direct-ir-map*\* and mapped to ```(op +)``` to which the result of generating IR for all other elements of the list (a b) - ```(element-array (symbol "v") (string "b")) (element-array (symbol "v") (string "a"))``` is appended.
    - If type of *expr* is not found in direct translation hash-table, then ```cons-to-ir``` looks for the type in \**maxima-special-ir-map*\* which returns the function name to handle the translation of expr-type. ```cons-to-ir``` then calls the returned function with *expr* as an argument.
      Example:
        
      ```lisp
      (%i11) show_form(g(x):=x^2);
      ((mdefine simp) (($g) $x) ((mexpt) $x 2))
      ```
      ```lisp
      (%i12) pytranslate(g(x):=x^2, t);
      ```
      ```lisp
      /* Generated IR */
      (body
       (body
        (func-def (symbol "g")
                  ((symbol "x") (op-no-bracket = (symbol "v") (symbol "v")))
                  (body-indented
                      (op-no-bracket = (symbol "v") (funcall (symbol "stack") (dictionary) (symbol "v")))
                      (obj-funcall (symbol "v") (symbol "ins") (dictionary ((string "x") (symbol "x"))))
                      (funcall (symbol "return")
                               (funcall (element-array (symbol "f") (string "pow"))
                                        (element-array (symbol "v") (string "x"))
                                        (num 2 0)))))
        (op-no-bracket = (element-array (symbol "f") (string "g")) (symbol "g"))))  
      ```
      ```python
      (%o12) 
      def g(x, v = v):
          v = Stack({}, v)
          v.ins({"x" : x})
          return(f["pow"](v["x"], 2))
      f["g"] = g
      ```
	
      Here, ```mdefine```, which is the type of *expr*, is present in \**maxima-special-ir-map*\* which returns *func-def-to-ir* as handler function for ```mdefine```, which is then called with *expr* for IR generation.
* After the generation of IR, the function *ir-to-python* is called with the generated IR as an argument, which recursively performes code generation.
     - ir-to-python looks for lisp ```(car ir)```, i.e., the type of IR, in the hash-table \**ir-python-direct-templates*\*, which maps IR type to function handlers and calls the handler function with IR as an argument. 
	 - The handler function generates python3 code recursively as a string. It uses a template corresponding to the type of IR and calling ```ir-to-python``` on all subexpressions.
	 
### Future Scope
Maxima, being a vast language, Pytranslate supports a core subset of its main features. Future work in Pytranslate would extend it to support a broader base. This work can include:  
1. Defining procedures for translation of unique forms in Maxima to defined IR by modification of ```*maxima-special-ir-map*```
1. Extending IR definition to support more extensive python syntax by adding to ```*ir-python-direct-templates*```
1. Implementation of Maxima functions in Python and adding to the functions mapping in pytranslate.py

Maxima function whose translation isn't currently defined can easily be translated by defining an equivalent function in python and adding it to pytranslate.py.  

Work on symbolic manipulation was not performed during Google Summer of Code and can be looked into for extending Pytranslate, as described.

During the initial project development, direct variable access in Python was being used, which however resulted in issues with maxima variable scoping in python. Currently, the class Stack, which defines a dictionary-like access to maxima variables in python, is used. Benchmarking shows a 2-7x slow down in speed compared to direct variable access. An alternative mechanism for variable access would be a step towards faster and more readable translation.

Further, Pytranslate can be modified to write the generated python output to a python module, and perform integrated Maxima and Python tests.

### Student Developer Information
| Name | Lakshya A Agrawal |
|:--:|:--:|
| GitHub | [LakshyAAAgrawal](https://github.com/LakshyAAAgrawal) |
| Matrix | [LakshyAAAgrawal](https://matrix.to/#/@lakshyaaagrawal:matrix.org)
| LinkedIn | [LakshyAAAgrawal](https://www.linkedin.com/in/LakshyAAAgrawal)
| Twitter | [LakshyAAAgrawal](https://twitter.com/lakshyaaagrawal)
| Mastodon | [@LakshyAAAgrawal@fosstodon.org](https://fosstodon.org/@LakshyAAAgrawal)
| E-Mail | [lakshya.aagrawal@gmail.com](mailto://lakshya.aagrawal@gmail.com)

### Commits
Commit|Description|
--|--|
[[304a29]](https://sourceforge.net/u/philomath/maxima_translate/ci/304a298d768f20c9e1761cc8ca35445c40ebbaff/) | Merge branch 'translation' including documentation - Latest commit as part of Google Summer of Code development
[[defa4a]](https://sourceforge.net/u/philomath/maxima_translate/ci/defa4aea39995e87676e156ff42dafd0a93bcaf3/) | Documentation on working and extension of pytranslate
[[5d3d1c]](https://sourceforge.net/u/philomath/maxima_translate/ci/5d3d1ca3ed37b0900370e99164caf41ef542edc6/) | Merge branch 'translation' with pytranslate, Maxima to Python Translator
[[d4781a]](https://sourceforge.net/u/philomath/maxima_translate/ci/d4781a32072a7120f7f49502794d66e810460af7/) | Made minor correction in function variable mapping name
[[4209df]](https://sourceforge.net/u/philomath/maxima_translate/ci/4209df696b37848cca4837f0896337530ff5cea4/) | Preparation for final merging into master - Documentation file pytranslate.texi
[[67a246]](https://sourceforge.net/u/philomath/maxima_translate/ci/67a24606547b1b5954253ff582381a33bcfac7ee/) | Add support for plotting 2D and 3D functions. Add cantorr.py as example translation.
[[45fa67]](https://sourceforge.net/u/philomath/maxima_translate/ci/45fa679177f40e465cd2ad2b1c96f71a82c63081/) | Make changes for multiple function plots, support for integration using quadpack from mpmath
[[c51c95]](https://sourceforge.net/u/philomath/maxima_translate/ci/c51c95bcf33fa7e29ee9f8ccf6dbdfb0a595e660/) | Add support for translation of code plotting 2D functions, using matplotlib and numpy. Make changes for adding all functions to functions dictionary after declaration
[[ed1d8b]](https://sourceforge.net/u/philomath/maxima_translate/ci/ed1d8bbf3d08dc53ba37de3beda70e0189468f79/) | Make changes for initialization of HierarchicalDict during function execution rather than declaration. Introduce cantorr2 as testcase, evaluates cantor function
[[dc68eb]](https://sourceforge.net/u/philomath/maxima_translate/ci/dc68eb27dd4fe9798a5dde0be2c833fe94c29897/) | Make changes to support handling of array indexes, fixes bug
[[f1626c]](https://sourceforge.net/u/philomath/maxima_translate/ci/f1626c6a1ca38787c8498bad6ac4b076606d0763/) | Make changes for appropriate handling of if-else within function calls, and as statements. Add numberp, listp, and length functions in pytranslate.py
[[3b481c]](https://sourceforge.net/u/philomath/maxima_translate/ci/3b481c02bb86e92fdf815f9966089c9c144c8f16/) | Add support for both types of control structures: if and conditionals
[[507fbb]](https://sourceforge.net/u/philomath/maxima_translate/ci/507fbba5e9695540883fc3ae5f9cdf31c133e8ef/) | Merge branch 'translation_dictionary' into translation, introducing HierarchicalDict and pytranslate with corresponding changes for appropriate scoping of maxima variables in python
[[129b26]](https://sourceforge.net/u/philomath/maxima_translate/ci/129b26cb4eacb2192da533e20bed5f2d6ed4b717/) | Finished code changes for use of HierarchicalDict in pytranslate
[[075bad]](https://sourceforge.net/u/philomath/maxima_translate/ci/075bad75039a1513c1f87f12c89efa812c70c61b/) | Introduce HierarchicalDict handling maxima variable scoping in python and modify translation of mprogn/mprog. Introduce functions 'num' and 'denom' in pytranslate.py
[[f38107]](https://sourceforge.net/u/philomath/maxima_translate/ci/f3810765e5f880ca3ef77de66a6906b2cb51bfd4/) | Introduce pytranslate.py, with mappings for maxima functions and variables in python. Add support for python dictionaries and object function calls. Introduced function preprocess for testing.
[[c9fd8e]](https://sourceforge.net/u/philomath/maxima_translate/ci/c9fd8ef52c13f26f042203b84c28021df0ff190f/) | Add support for mreturn() funcall and a testcase for endcons
[[0fef6a]](https://sourceforge.net/u/philomath/maxima_translate/ci/0fef6a6a299d2572c3dcaa3a29dc1d4263850852/) | Add support for endons, floor, fix, sqrt, uninitialized for loop. Add option print-ir to pytranslate. Bug fixes.
[[4518e0]](https://sourceforge.net/u/philomath/maxima_translate/ci/4518e06afcf5e686f4ff7ccaeb8adacfb411dd0e/) | Merge branch 'translation' to 'master'
[[acef78]](https://sourceforge.net/u/philomath/maxima_translate/ci/acef78d97760a0542279c75b627c628b574764df/) | Add English texinfo documentation for pytranslate, Maxima to Python Translator.
[[808eba]](https://sourceforge.net/u/philomath/maxima_translate/ci/808eba44177b55b9237de6ca590de36f1a8794aa/) | Made minor changes in main Maxima README and Documentation fixing references about adding directory to share
[[8d1816]](https://sourceforge.net/u/philomath/maxima_translate/ci/8d1816220ae69f7b37afaa8e81f467d547af6e40/) | Add test for multiple expressions in lambda
[[c957a1]](https://sourceforge.net/u/philomath/maxima_translate/ci/c957a1703647c1f9231449d873a077d0230848aa/) | Add support for variants of *for* loop
[[a5079b]](https://sourceforge.net/u/philomath/maxima_translate/ci/a5079bd6f57b6aec49aca742021435c46087ca49/) | Add tests for forms generating random function names with gensym(block, mprogn, mprog) by use of regex
[[aef408]](https://sourceforge.net/u/philomath/maxima_translate/ci/aef408d5f30f48d25df7219151815aadf12d7be1/) | Add support for "for loop through list" -> *for var in list do exp*. mprogn within *for* loop is converted to IR *block-indented*.
[[92ef66]](https://sourceforge.net/u/philomath/maxima_translate/ci/92ef660679e15aeb26484192334c7c9181b9127b/) | Make changes for return of last expression in function definition, pass function arguments to generated block function
[[0051f4]](https://sourceforge.net/u/philomath/maxima_translate/ci/0051f47937daf31768dff82979e2aa35b63405d3/) | Add support for multiple expressions in lambda forms along with optional variables
[[9d991a]](https://sourceforge.net/u/philomath/maxima_translate/ci/9d991abfc615c23858d5e40dd7861101b0d4af7d/) | Add support for Lambda forms along with tests
[[b3ef84]](https://sourceforge.net/u/philomath/maxima_translate/ci/b3ef844061797141a1e5c7ca2cdd95730a960a70/) | Make changes for appropriate conversion of symbol names, preserving symbol name case
[[25f90b]](https://sourceforge.net/u/philomath/maxima_translate/ci/25f90b7f1d99bf68782642d7125c9d15878bf69e/) | Add test file rtest_pytranslate.mac for testing Maxima to Python Translator
[[b9f2b7]](https://sourceforge.net/u/philomath/maxima_translate/ci/b9f2b719af4ca6e68cf1d3e76f52cfe24c559f90/) | Fix variable reference error
[[2a3c40]](https://sourceforge.net/u/philomath/maxima_translate/ci/2a3c4001f6db2bbf1b96946649e7114deaf20b5e/) | Changes based on code review from community
[[80d851]](https://sourceforge.net/u/philomath/maxima_translate/ci/80d85199734f80421f7fa34174c0c7b2cbd316d9/) | Add nformat preprocessing prior to translation
[[9481a9]](https://sourceforge.net/u/philomath/maxima_translate/ci/9481a98bd817aa43d5ed3d5ca670dae1af4ebf53/) | Rename from transpiler to pytranslate
[[516107]](https://sourceforge.net/u/philomath/maxima_translate/ci/51610763a6f0543ae764309c312d3d07b02a3898/) | Add support for conversion of IR to Python code - introduce function ir-to-python
[[c567f6]](https://sourceforge.net/u/philomath/maxima_translate/ci/c567f6a6fc614983c63c10822a8db38dee19f12f/) | Fixed mfactorial bug, work on conversion of mprogn, mprog and if-else expressions
[[dac397]](https://sourceforge.net/u/philomath/maxima_translate/ci/dac3977e971663a93e116012d741ff2ac09dd410/) | Modify function handling conversion of Maxima functions to IR to handle variable argument lists
[[466ad6]](https://sourceforge.net/u/philomath/maxima_translate/ci/466ad682c827350f420e8d4049f4d4f926d5a981/) | Add support for conversion to IR of logic operators, relational operators and array references.
[[52a772]](https://sourceforge.net/u/philomath/maxima_translate/ci/52a7724ecb75519f9327f8ce35c99d843ba7ffee/) | Add support for converting block(progn) statements, and array definitions to IR.
[[9677c4]](https://sourceforge.net/u/philomath/maxima_translate/ci/9677c4d5052ab698ecfaa95a23dba7e064487ba7/) | Add maxima-to-ir support for function definition, lists, and assignment operator. A detailed conversion chart is present in the file share/transpiler/maxima-to-ir.html
[[31d48d]](https://sourceforge.net/u/philomath/maxima_translate/ci/31d48d8eaac0e4128d308aef12279c46ab817a37/) | Started work on maxima-to-ir function.
[[764b7a]](https://sourceforge.net/u/philomath/maxima_translate/ci/764b7a8aa8737399c404e6c7a1191b93d62abbe2/) | Initial Commit

### Other contributions
I also worked on implementation of the Quine Mccluskey algorithm for boolean simplification under the name of Ksimplifier in share/logic package. Ksimplifier was introduced through [merge #10](https://sourceforge.net/p/maxima/code/merge-requests/10/). Bug fixes inroduced through [merge #17](https://sourceforge.net/p/maxima/code/merge-requests/17/) based on inputs from Stavros Macrakis.
