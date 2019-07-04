(defparameter *maxima-function-dictionary-name* "m_func")
(defparameter *maxima-variables-dictionary-name* "m_var")
(defparameter *maxima-variables-dictionary-name-in-functions* "m_var_l")
(defparameter *symbols-directly-convert* '()
  "List containing symbols to be converted as it is to Python symbols rather than maxima_vars[\"symbol\"]")

(defvar *maxima-direct-ir-map*
  (let ((ht (make-hash-table)))
    (setf (gethash 'mtimes ht) '(op *))
    (setf (gethash 'mplus ht) '(op +))
    (setf (gethash 'mexpt ht) `(funcall (element-array (symbol ,*maxima-function-dictionary-name*) (string "pow"))))
    (setf
     (gethash 'mfactorial ht)
     `(funcall (element-array (symbol ,*maxima-function-dictionary-name*) (string "factorial"))))
    (setf (gethash 'rat ht) '(op /))
    (setf (gethash 'mquotient ht) '(op /))
    (setf (gethash 'mlist ht) '(struct-list))
    (setf (gethash 'mand ht) '(boolop (symbol "and")))
    (setf (gethash 'mor ht) '(boolop (symbol "or")))
    (setf (gethash 'mnot ht) '(funcall (symbol "not")))
    (setf (gethash 'mminus ht) '(unary-op -))
    (setf (gethash 'mgreaterp ht) '(comp-op >))
    (setf (gethash 'mequal ht) '(comp-op ==))
    (setf (gethash 'mnotequal ht) '(comp-op !=))
    (setf (gethash 'mlessp ht) '(comp-op <))
    (setf (gethash 'mgeqp ht) '(comp-op >=))
    (setf (gethash 'mleqp ht) '(comp-op <=))
    (setf (gethash '$floor ht) '(funcall (symbol "math.floor")))
    (setf (gethash '$fix ht) '(funcall (symbol "math.floor")))
    (setf (gethash '%fix ht) '(funcall (symbol "math.floor")))
    (setf (gethash '%sqrt ht) '(funcall (symbol "math.sqrt")))
    (setf (gethash 'mreturn ht) '(funcall (symbol "return")))
    ht))

(defvar *maxima-special-ir-map*
  (let ((ht (make-hash-table)))
    (setf (gethash 'mdefine ht) 'func-def-to-ir)
    (setf (gethash '%array ht) 'array-def-to-ir)
    (setf (gethash 'mprog ht) 'mprog-to-ir)
    (setf (gethash 'mprogn ht) 'mprogn-to-ir)
    (setf (gethash 'mcond ht) 'mcond-to-ir)
    (setf (gethash 'lambda ht) 'lambda-to-ir)
    (setf (gethash 'mdoin ht) 'for-list-to-ir)
    (setf (gethash 'mdo ht) 'for-loop-to-ir)
    (setf (gethash '%endcons ht) 'endcons-to-ir)
    (setf (gethash '$endcons ht) 'endcons-to-ir)
    (setf (gethash 'msetq ht) 'assignment-to-ir)
    ht))

(defvar *ir-forms-to-append* '())

(defun clast (l)
  (car (last l)))

; Check if form is mprogn
(defun mprogn-p (form)
  (and (consp (clast form))
       (consp (car (clast form)))
       (eq (caar (clast form)) 'mprogn)))

(defun symbol-name-to-string (form)
  (maybe-invert-string-case (symbol-name (stripdollar form))))

(defun symbol-to-ir (form)
  `(symbol ,(symbol-name-to-string form)))

(defun symbol-to-dictionary-ir (form)
  `(element-array (symbol ,*maxima-variables-dictionary-name*) (string ,(symbol-name-to-string form))))

(defun assignment-to-ir (form)
  `(assign ,(maxima-to-ir (cadr form)) ,(maxima-to-ir (caddr form))))

(defun symbol-to-asterisk-ir (form)
  (list 'symbol
	(concatenate 'string "*"
		     (maybe-invert-string-case (symbol-name (stripdollar form))))))
  
(defun endcons-to-ir (form)
  (cond ((consp (clast form))
	 (maxima-to-ir (append (clast form) `(,(cadr form)))))
	(t
	 `(struct-list ,(symbol-to-asterisk-ir (clast form)) ,(maxima-to-ir (cadr form))))))
  
(defun for-loop-to-ir (form)
  (cond ((null (caddr (cdddr form))) ; Condition Specified
	 `(body ,@(cond ((null (cadr form)) '()) ; If variable not given
			(t `((assign ,(maxima-to-ir (cadr form)) ; If variable assigned by "for var:value"
				     ,(maxima-to-ir (caddr form))))))
		(while-loop
		 ,(cond ((and
			  (consp (clast (butlast form)))
			  (consp (car (clast (butlast form))))
			  (eq 'mnot (caar (clast (butlast form)))))
			 (maxima-to-ir (cadr (clast (butlast form)))))
			(t
			 `(funcall (symbol "not")
				  ,(maxima-to-ir (clast (butlast form))))))
		 (body-indented
		  ,@(cond ((mprogn-p form)
			   (mapcar 'maxima-to-ir (cdr (clast form))))
			  (t
			   `(,(maxima-to-ir (clast form)))))
		  ,@(cond ((null (cadddr form)) '())
			  (t `((assign ,(maxima-to-ir (cadr form))
				       (op + ,(maxima-to-ir (cadr form)) ,(maxima-to-ir (cadddr form)))))))))
		,@(cond ((null (cadr form)) '()) ; If variable not given
			(t `((del ,(maxima-to-ir (cadr form))))))))
	(t                           ; Limit specified
	 `(for-list ,(maxima-to-ir (cadr form))
		    (funcall (symbol "range")
			     ,(maxima-to-ir (caddr form))
			     (op +
				 ,(maxima-to-ir (caddr (cdddr form)))
				 (num 1 0))
			     ,(maxima-to-ir (cadddr form))
			     )
		    (body-indented
		     ,@(cond ((mprogn-p form)
			      (mapcar 'maxima-to-ir (cdr (clast form))))
			     (t
			      `(,(maxima-to-ir (clast form))))))))))

(defun for-list-to-ir (form)
  `(for-list ,(maxima-to-ir (cadr form))
	     ,(maxima-to-ir (caddr form))
	     (body-indented
	      ,@(cond ((mprogn-p form)
		       (mapcar 'maxima-to-ir (cdr (clast form))))
		      (t
		       `(,(maxima-to-ir (clast form))))))))

(defun func-call-arg-to-ir (form)
  (typecase form
    (cons (cond
	    ((eq (caar form) 'mlist)
	     `(symbol ,(maybe-invert-string-case (symbol-name (stripdollar (cadr form))))))))
    (t (maxima-to-ir form))))

(defun lambda-to-ir (form)
  (cond ((eq (list-length (cddr form)) 1)
	 `(lambda ,(mapcar #'func-arg-to-ir (cdadr form)) ,(maxima-to-ir (clast form))))
	(t
	 (let ((func_name (maxima-to-ir (gensym "$FUNC"))))
	   (setf *ir-forms-to-append*
		 (append *ir-forms-to-append*
			 `((func-def
			    ,func_name
			    ,(mapcar 'func-call-arg-to-ir
				     (cdadr form))
			    (body-indented
			     ,@(mapcar 'maxima-to-ir
				       (butlast (cddr form)))
			     (funcall (symbol "return") ,(maxima-to-ir (car (last form)))))))))
	   `(lambda ,(mapcar #'func-arg-to-ir (cdadr form)) (funcall ,func_name ,@(mapcar #'func-call-arg-to-ir (cdadr form))))))))

(defun mcond-auxiliary (forms)
  `( ,(maxima-to-ir (car forms))
     ,(maxima-to-ir (cadr forms))
     ,(cond ((eq (caddr forms) 't) (maxima-to-ir (cadddr forms)))
	    (t `(conditional ,@(mcond-auxiliary (cddr forms)))))
     ))

(defun mcond-to-ir (form)
  ;; (conditional <condition> <res1> <else-res>)
  `(conditional ,@(mcond-auxiliary (cdr form))))

(defun mprog-variable-names-list (form)
  (cond ((and (consp form) (eq 'msetq (caar form))) (maxima-to-ir (cadr form)))
	(t (maxima-to-ir form))))

(defun mprog-arg-list (form)
  (cond ((and (consp form) (eq 'msetq (caar form))) (maxima-to-ir (clast form)))
	(t `(symbol "None"))))

;;; It creates a function for the statements.
;;; A problem with this approach is that Maxima is dynamically
;;; binding, whereas Python is not. For accessing values from the
;;; global context, this will work, however, for assignment
;;; operations, this method will not. Another alternative that can
;;; be considered is to create a class to house all the bindings.
(defun mprog-to-ir (form &optional (func-args '()))
  (cond ((not (null (cdr form)))
	 (cond ((and (consp (cadr form)) (eq 'mlist (caaadr form)))
		;; Variable binding
		(let ((func_name (maxima-to-ir (gensym "$FUNC"))))
		  (setf *ir-forms-to-append*
			(cons `(func-def ,func_name
					 ,(append func-args
						  (mapcar 'mprog-variable-names-list (cdadr form)))
					 (body-indented ,@(mapcar 'maxima-to-ir (butlast (cddr form)))
							(funcall (symbol "return")
								 ,(maxima-to-ir (clast form)))))
			      *ir-forms-to-append*))
		  `(funcall ,func_name ,@(append func-args (mapcar 'mprog-arg-list (cdadr form))))))
	       ;; No variable binding required
	       (t
		(let ((func_name (maxima-to-ir (gensym "$FUNC"))))
		  (setf *ir-forms-to-append*
			(cons `(func-def ,func_name
					 ,func-args
					 (body-indented ,@(mapcar 'maxima-to-ir (butlast (cdr form)))
							(funcall (symbol "return")
								 ,(maxima-to-ir (clast form)))))
			      *ir-forms-to-append*))
		  `(funcall ,func_name ,@func-args))
		)))))

(defun mprogn-to-ir (form &optional (func-args '()))
  (let ((func_name (maxima-to-ir (gensym "$FUNC"))))
    (setf *ir-forms-to-append*
	  (cons `(func-def ,func_name
			   ,func-args
			   (body-indented
			    ,@(mapcar 'maxima-to-ir
				      (butlast (cdr form)))
			    (funcall (symbol "return") ,(maxima-to-ir (clast form)))))
		*ir-forms-to-append*))
    `(funcall ,func_name ,@func-args)))

;;; Recursively generates IR for a multi-dimensional array and fills all cells with Null value
(defun array-gen-ir (dimensions)
  (cond ((null dimensions) '(symbol "None"))
	(t `(op * (struct-list ,(array-gen-ir (cdr dimensions))) ,(maxima-to-ir (car dimensions))))))

;;; Helper function for array-def-to-ir which generates the IR for array definition 
(defun auxillary-array-to-ir (symbol dimensions)
  `(assign ,symbol ,(array-gen-ir dimensions)))

;;; Function to generate IR for array definition using different methods, by using the auxillary function
(defun array-def-to-ir (form)
  (cond ((consp (cadr form))
	 (append '(body) (loop for symb in (cdadr form)
				  collect (auxillary-array-to-ir (maxima-to-ir symb) (cddr form)))))
	((not (numberp (caddr form)))
	 (auxillary-array-to-ir (maxima-to-ir (cadr form)) (cdddr form)))
	(t
	 (auxillary-array-to-ir (maxima-to-ir (cadr form)) (cddr form)))))

;;; Function to convert reference to array elements to IR
;;; TODO : However, for arrays that are undefined, it needs to be assigned to a hashed array(dictionary)
(defun array-ref-to-ir (symbol indices)
  (cond ((null indices) (maxima-to-ir symbol)) 
	(t `(element-array ,(array-ref-to-ir symbol (butlast indices)) ,(maxima-to-ir (clast indices))))))

;;; Convert Function args to corresponding IR
;;; Convert the optional list argument into corresponding *args form in python
(defun func-arg-to-ir (form)
  (typecase form
    (cons (cond
	    ((eq (caar form) 'mlist)
	     `(symbol ,(concatenate 'string "*"  (symbol-name-to-string (cadr form)))))))
    (t (symbol-to-ir form))))

;;; Generates IR for function definition
(defun func-def-to-ir (form)
  `(func-def
    ,(symbol-to-ir (caaadr form))
    ,@(let ((func-args (mapcar #'func-arg-to-ir (cdadr form))))
	(cons
	 (append func-args
		 `((op-no-bracket =
				  (symbol ,*maxima-variables-dictionary-name-in-functions*)
				  (symbol ,*maxima-variables-dictionary-name*))))
	 (let ((*maxima-variables-dictionary-name* *maxima-variables-dictionary-name-in-functions*)
	       (*symbols-directly-convert* (mapcar
					    (lambda (x) (typecase x
							  (cons (cadr x))
							  (t x)))
					    (cdadr form))))
	   `((body-indented (funcall (symbol "return")
				     ,(cond ((and (consp (caddr form))
						  (consp (caaddr form))
						  (eq (car (caaddr form)) 'mprog))
					     (mprog-to-ir (caddr form)
							  (mapcar #'func-arg-to-ir (cdadr form))))
					    ((and (consp (caddr form))
						  (consp (caaddr form))
						  (eq (car (caaddr form)) 'mprogn))
					     (mprogn-to-ir (caddr form)
							   (mapcar #'func-arg-to-ir (cdadr form))))
					    (t
					     (maxima-to-ir (caddr form))))))))))))

;;; Generates IR for atomic forms
(defun atom-to-ir (form)
  (cond
    ((eq form 'nil) `(symbol "None"))
    ((eq form '$true) `(symbol "True"))
    ((stringp form) `(string ,form))
    ((not (symbolp form)) `(num ,form 0))
    ((eq form '$%i) '(num 0 1)) ; iota complex number
    ((eq form '$%pi) '(num (symbol "math.pi") 0)) ; Pi
    ((eq form '$%e) '(num (symbol "math.e") 0)) ; Euler's Constant
    (t
     (cond
       ((member form *symbols-directly-convert*) (symbol-to-ir form))
       (t (symbol-to-dictionary-ir form))))
    ))

;;; Generates IR for non-atomic forms
(defun cons-to-ir (form)
  (cond
    ((atom (caar form))
     (let ((type (gethash (caar form) *maxima-direct-ir-map*)))
       (cond
					; If the form is present in *maxima-direct-ir-map*
	 (type
	  (append type (mapcar #'maxima-to-ir (cdr form))))
	 ; If the form is to be transformed in a specific way
	 ((setf type (gethash (caar form) *maxima-special-ir-map*))
	  (funcall type form))
	 ((member 'array (car form))
	  (array-ref-to-ir (caar form) (cdr form)))
	 (t
	  (append `(funcall ,(maxima-to-ir (caar form)))
		  (mapcar #'maxima-to-ir (cdr form))))
	 )))))

;;; Generates IR for Maxima expression
(defun maxima-to-ir (form &optional (is_stmt nil))
  (let
      ((ir (cond ((atom form)
		  (atom-to-ir form))
		 ((and (consp form) (consp (car form)))
		  (cons-to-ir form))
		 (t
		  (cons 'no-convert form))
		 )))
    (cond (is_stmt (append '(body)
			   *ir-forms-to-append*
			   `(,ir)))
	  (t ir))))

;;; Driver function for the translator, calls the function
;;; maxima-to-ir and then ir-to-python
(defun $pytranslate (form &optional (print-ir nil))
  (setq *ir-forms-to-append* '())
  (setf form (nformat form))
  (cond (print-ir (ir-to-python (print (maxima-to-ir form t))))
	(t (ir-to-python (maxima-to-ir form t)))))

(defvar *ir-python-direct-templates*
  (let ((ht (make-hash-table)))
    (setf (gethash 'num ht) 'num-to-python)
    (setf (gethash 'body ht) 'body-to-python)
    (setf (gethash 'body-indented ht) 'body-indented-to-python)
    (setf (gethash 'op ht) 'op-to-python)
    (setf (gethash 'op-no-bracket ht) 'op-no-bracket-to-python)
    (setf (gethash 'comp-op ht) 'op-to-python)
    (setf (gethash 'boolop ht) 'op-to-python)
    (setf (gethash 'op ht) 'op-to-python)
    (setf (gethash 'del ht) 'del-to-python)
    (setf (gethash 'unary-op ht) 'unary-op-to-python)
    (setf (gethash 'symbol ht) 'symbol-to-python)
    (setf (gethash 'assign ht) 'assign-to-python)
    (setf (gethash 'string ht) 'string-to-python)
    (setf (gethash 'funcall ht) 'funcall-to-python)
    (setf (gethash 'struct-list ht) 'struct-list-to-python)
    (setf (gethash 'func-def ht) 'func-def-to-python)
    (setf (gethash 'element-array ht) 'element-array-to-python)
    (setf (gethash 'conditional ht) 'conditional-to-python)
    (setf (gethash 'lambda ht) 'lambda-to-python)
    (setf (gethash 'for-list ht) 'for-list-to-python)
    (setf (gethash 'while-loop ht) 'while-loop-to-python)
    (setf (gethash 'obj-funcall ht) 'obj-funcall-to-python)
    (setf (gethash 'obj-funcall ht) 'obj-funcall-to-python)
    (setf (gethash 'dictionary ht) 'dictionary-to-python)
    ht))

;;; Generates Python source for given IR form
(defun ir-to-python (form &optional
			    (indentation-level 0)
			    (is_stmt nil))
  (concatenate
   'string
   (cond
     (is_stmt ; To determine if the form needs to be indented
      (format nil "~v@{~A~:*~}" indentation-level "    "))
     (t ""))
   (typecase form
     (cons
      (let ((type (gethash (car form) *ir-python-direct-templates*)))
	(cond
	  (type (funcall type form indentation-level))
	  (t (format nil "no-covert : (~a)" form))
	  )))	
     (t
      (format nil "~a" form)))))

;;; Code below is for functions handling specefic IR forms and
;;; generating the corresponding Python code.

(defun dictionary-to-python (form indentation-level)
  (format nil "{}"))

(defun obj-funcall-to-python (form indentation-level)
  (format nil "~a.~a(~{~a~^, ~})"
	  (ir-to-python (cadr form))
	  (ir-to-python (caddr form))
	  (mapcar
	   (lambda (elm) (ir-to-python elm indentation-level))
	   (cdddr form))))	  

(defun while-loop-to-python (form indentation-level)
  (format nil "while ~a:~&~a"
	  (ir-to-python (cadr form) indentation-level)
	  (ir-to-python (caddr form) indentation-level)))

(defun for-list-to-python (form indentation-level)
  (format nil "for ~a in ~a:~&~a"
	  (ir-to-python (cadr form) indentation-level)
	  (ir-to-python (caddr form) indentation-level)
	  (ir-to-python (clast form) indentation-level)))

(defun lambda-to-python (form indentation-level)
  (format nil "lambda ~{~a~^, ~}: ~a"
	  (mapcar
	   (lambda (elm) (ir-to-python elm indentation-level))
	   (cadr form))
	  (ir-to-python (clast form) indentation-level)
	  ))

(defun conditional-to-python (form indentation-level)
  (format nil "(~a if ~a else ~a)"
	  (ir-to-python (caddr form) indentation-level)
	  (ir-to-python (cadr form) indentation-level)
	  (ir-to-python (cadddr form) indentation-level)))

(defun element-array-to-python (form indentation-level)
  (format nil "~a[~a]"
	  (ir-to-python (cadr form) indentation-level)
	  (ir-to-python (clast form) indentation-level)))
  
(defun func-def-to-python (form indentation-level)
  (format nil "def ~a(~{~a~^, ~}):~&~a"
	  (ir-to-python (cadr form))
	  (mapcar
	   (lambda (elm) (ir-to-python elm indentation-level))
	   (caddr form))
	  (ir-to-python (clast form) indentation-level)
	  ))

(defun struct-list-to-python (form indentation-level)
  (format nil "[~{~a~^, ~}]"
	  (mapcar
	   (lambda (elm) (ir-to-python elm indentation-level))
	   (cdr form))))

(defun unary-op-to-python (form indentation-level)
  (format nil "(~a~a)"
	  (cadr form)
	  (ir-to-python (caddr form) indentation-level)))

(defun del-to-python (form indentation-level)
  (format nil "del ~a"
	  (ir-to-python (cadr form))))

(defun funcall-to-python (form indentation-level)
  (format nil "~a(~{~a~^, ~})"
	  (ir-to-python (cadr form))
	  (mapcar
	   (lambda (elm) (ir-to-python elm indentation-level))
	   (cddr form))))

(defun string-to-python (form indentation-level)
  (format nil "~c~a~c"
	  #\"
	  (cadr form)
	  #\"))
  
(defun assign-to-python (form indentation-level)
  (format nil "~a = ~a"
	  (ir-to-python (cadr form))
	  (ir-to-python (caddr form))))

(defun symbol-to-python (form indentation-level)
  (cadr form))

(defun op-no-bracket-template (op)
  (format nil "~@?" "~~{~~#[~~;~~a~~:;~~a ~a ~~]~~}"
	  op))

(defun op-no-bracket-to-python (form indentation-level)
  (format nil (op-no-bracket-template (ir-to-python (cadr form)))
	  (mapcar
	   (lambda (elm) (ir-to-python elm indentation-level))
	   (cddr form))))

(defun op-template (op)
  (format nil "~@?" "(~~{~~#[~~;~~a~~:;~~a ~a ~~]~~})"
	  op))

(defun op-to-python (form indentation-level)
  (format nil (op-template (ir-to-python (cadr form)))
	  (mapcar
	   (lambda (elm) (ir-to-python elm indentation-level))
	   (cddr form))))

;; "~{~&~a~}" but there was a problem regarding this with indentation:
;; pytranslate('(while cond do (while cond do (while cond do expr))));
;; (%o2) None = None
;; while not(not(cond)):
;;         None = None
;;     while not(not(cond)):
;;                 None = None
;;         while not(not(cond)):
;;             expr
;;             None = (None + None)
;;         del None
;;         None = (None + None)
;;     del None
;;     None = (None + None)
;; del None
;; The lines None=None arent properly indented
;; Hence change to ~% for new line
(defun body-to-python (form indentation-level)
  (format nil "~{~%~a~}"
	  (mapcar
	   (lambda (elm) (ir-to-python elm indentation-level t))
	   (cdr form))))

(defun body-indented-to-python (form indentation-level)
  (format nil "~{~&~a~}"
	  (mapcar
	   (lambda (elm) (ir-to-python elm (1+ indentation-level) t))
	   (cdr form))))

(defun num-to-python (form indentation-level)
  (cond ((eq 0 (clast form)) (ir-to-python (cadr form)))
	(t "1j")))

;;; Function to display the internal Maxima form
(defun $show_form (form)
  (print (nformat-check form))) 