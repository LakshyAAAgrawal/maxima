;;; -*-  Mode: Lisp; Package: Maxima; Syntax: Common-Lisp; Base: 10 -*- ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     The data in this file contains enhancments.                    ;;;;;
;;;                                                                    ;;;;;
;;;  Copyright (c) 1984,1987 by William Schelter,University of Texas   ;;;;;
;;;     All rights reserved                                            ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "MAXIMA")

;; Temporarily we establish an array convention for conversion
;; of this file to new type arrays.

(eval-when (compile eval)

;; It is more efficient to use the value cell, and we can probably
;; do this everywhere, but for now just use it in this file.
	   
(defmacro nsymbol-array (x) `(symbol-value ,x))
;(defmacro nsymbol-array (x) `(get ,x 'array))

(defmacro narray (x typ &rest dims) typ
  `(setf (nsymbol-array ',x)
	 (make-array
	   ,(if (cdr dims) `(mapcar '1+ (list ,@ dims))
	      `(1+ ,(car dims))))))
)

(declare-top(flonum (j[0]-bessel flonum) (j[1]-bessel flonum)
		 (j[n]-bessel flonum fixnum) (i[0]-bessel flonum)
		 (i[1]-bessel flonum) (i[n]-bessel flonum fixnum)
		 (g[0]-bessel flonum) (g[1]-bessel flonum)
		 (g[n]-bessel flonum fixnum))
	 (flonum x z y xa sx0 sq co si q p)
	 (special $jarray $iarray $garray)
	 (array* (flonum j-bessel-array 1. i-bessel-array 1.
			 g-bessel-array 1.))
	 (array* (flonum $jarray 1. $iarray 1. $garray 1.))
	 (*fexpr $array)) 

#-(or cl NIL)
(and (not (get '*f 'subr)) 
     (mapc #'(lambda (x) (putprop x '(arith fasl dsk liblsp) 'autoload))
	   '(*f //f _f +f -f)))

#-NIL
(declare-top(flonum (*f flonum flonum) (//f flonum flonum) 
		 (_f flonum fixnum) (+f flonum flonum) (-f flonum flonum))
	 (*expr *f //f _f +f -f))

#+(or cl NIL)
(eval-when (eval compile)
  (defmacro *f (a b) `(*$ ,a ,b))
  (defmacro //f (a b) `(//$ ,a ,b))
  (defmacro +f (a b) `(+$ ,a ,b))
  (defmacro -f (a b) `(-$ ,a ,b))
  ;_f isn't used here.  That would be scale-float, no open-code version.
  )


;;
;; Bessel function of the first kind of order 0.
;;
;; One definition is
;;
;;         INF
;;         ====       k  2 k
;;         \     (- 1)  z
;;          >    -----------
;;         /       2 k   2
;;         ====   2    k!
;;         k = 0
;;
;; We only support computing this for real z.
;;
(defun j[0]-bessel (x) 
   (slatec:dbesj0 (float x 1d0)))

(defun $j0 ($x)
  (cond ((numberp $x)
	 (j[0]-bessel (float $x)))
	(t (list '($j0 simp) $x))))


;; Bessel function of the first kind of order 1.
;;
;; One definition is
;;
;;      INF
;;      ====   - 2 k - 1      k  2 k + 1
;;      \     2          (- 1)  z
;;       >    --------------------------
;;      /            k! (k + 1)!
;;      ====
;;      k = 0

(defun j[1]-bessel (x) 
   (slatec:dbesj1 (float x 1d0)))

(defun $j1 ($x)
  (cond ((numberp $x)
	 (j[1]-bessel (float $x)))
	(t (list '($j1 simp) $x))))

;; Bessel function of the first kind of order n
;;
;; The order n must be a non-negative real.
(defun $jn ($x $n)
  (cond ((and (numberp $x) (numberp $n) (>= $n 0))
	 (multiple-value-bind (n alpha)
	     (floor (float $n))
	   (let ((jvals (make-array (1+ n) :element-type 'double-float)))
	     (slatec:dbesj (float $x) alpha (1+ n) jvals 0)
	     (narray $jarray $float n)
	     (fillarray (nsymbol-array '$jarray) jvals)
	     (aref jvals n))))
	(t (list '($jn simp) $x $n))))


;; Modified Bessel function of the first kind of order 0.  This is
;; related to J[0] via
;;
;; I[0](z) = J[0](z*exp(%pi*%i/2))
;;
;; and
;;
;;        INF
;;        ====         2 k
;;        \           z
;;         >    ----------------
;;        /         2 k   2 
;;        ====     2    k!
;;        k = 0

(defun i[0]-bessel (x)
   (slatec:dbesi0 (float x 1d0)))

(defun $i0 ($x)
  (cond ((numberp $x)
	 (i[0]-bessel (float $x)))
	(t (list '($i0 simp) $x))))

;; Modified Bessel function of the first kind of order 1.  This is
;; related to J[1] via
;;
;; I[1](z) = exp(-%pi*%I/2)*J[0](z*exp(%pi*%i/2))
;;
;; and
;;
;;       INF
;;       ====         2 k
;;       \           z
;;        >    ----------------
;;       /      2 k
;;       ====  2    k! (k + 1)!
;;       k = 0

(defun i[1]-bessel (x)
  (slatec:dbesi1 (float x 1d0)))

(defun $i1 ($x)
  (cond ((numberp $x) (i[1]-bessel (float $x)))
	(t (list '($i1 simp) $x))))

;; Modified Bessel function of the first kind of order n, where n is a
;; non-negative real.
(defun $in ($x $n)
  (cond ((and (numberp $x) (numberp $n) (>= $n 0))
	 (multiple-value-bind (n alpha)
	     (floor (float $n))
	   (let ((jvals (make-array (1+ n) :element-type 'double-float)))
	     (slatec:dbesi (float $x) alpha 1 (1+ n) jvals 0)
	     (narray $iarray $float n)
	     (fillarray (nsymbol-array '$iarray) jvals)
	     (aref jvals n))))
	(t (list '($in simp) $x $n))))

(defun $bessel_i (arg order)
  (if (and (numberp order)
	   (numberp ($realpart arg))
	   (numberp ($imagpart arg)))
      ($in (complex ($realpart arg) ($imagpart arg)) order)
      (subfunmakes '$bessel_i (ncons order) (ncons arg))))

(defun bessel-i (arg order)
  (cond ((zerop (imagpart arg))
	 ;; We have numeric args and the first arg is purely
	 ;; real. Call the real-valued Bessel function.  We call i0
	 ;; and i1 instead of jn, if possible.
	 (let ((arg (realpart arg)))
	   (cond ((zerop order)
		  (slatec:dbesi0 arg))
		 ((= order 1)
		  (slatec:dbesi1 arg))
		 (t
		  (multiple-value-bind (n alpha)
		      (floor (float order))
		    (let ((jvals (make-array (1+ n) :element-type 'double-float)))
		      (slatec:dbesi (float (realpart arg)) alpha 1 (1+ n) jvals 0)
		      (narray $besselarray $float n)
		      (fillarray (nsymbol-array '$besselarray) jvals)
		      (aref jvals n)))))))
	(t
	 ;; The first arg is complex.  Use the complex-valued Bessel
	 ;; function
	 (multiple-value-bind (n alpha)
	     (floor (float order))
	   (let ((cyr (make-array (1+ n) :element-type 'double-float))
		 (cyi (make-array (1+ n) :element-type 'double-float)))
	     (multiple-value-bind (v-zr v-zi v-fnu v-kode v-n
					v-cyr v-cyi v-nz v-ierr)
		 (slatec::zbesi (float (realpart arg))
				(float (imagpart arg))
				alpha
				1
				(1+ n)
				cyr
				cyi
				0
				0)
	       (declare (ignore v-zr v-zi v-fnu v-kode v-n
				v-cyr v-cyi))

	       ;; We should check for errors here based on the
	       ;; value of v-ierr.
	       (when (plusp v-ierr)
		 (format t "zbesi ierr = ~A~%" v-ierr))
	       (narray $besselarray $complete (1+ n))
	       (dotimes (k (1+ n)
			 (arraycall 'flonum (nsymbol-array '$besselarray) n))
		 (setf (arraycall 'flonum (nsymbol-array '$besselarray) k)
		       (simplify (list '(mplus)
				       (simplify (list '(mtimes)
						       '$%i
						       (aref cyi k)))
				       (aref cyr k)))))))))))


;; I think g0(x) = exp(-x)*I[0](x), g1(x) = exp(-x)*I[1](x), and
;; gn(x,n) = exp(-x)*I[n](x), based on some simple numerical
;; evaluations.

(defun $g0 ($x)
  (cond ((numberp $x)
	 (slatec:dbsi0e (float $x)))
	(t (list '($g0 simp) $x))))

(defun $g1 ($x)
  (cond ((numberp $x)
	 (slatec:dbsi1e (float $x)))
	(t (list '($g1 simp) $x))))


(declare-top (fixnum i n) (flonum x q1 q0 fn fi b1 b0 b an a1 a0 a)) 

(defun $gn ($x $n)
  (cond ((and (numberp $x) (integerp $n))
	 (multiple-value-bind (n alpha)
	     (floor (float $n))
	   (let ((jvals (make-array (1+ n) :element-type 'double-float)))
	     (slatec:dbesi (float $x) alpha 2 (1+ n) jvals 0)
	     (narray $iarray $float n)
	     (fillarray (nsymbol-array '$iarray) jvals)
	     (aref jvals n))))
	(t (list '(gn simp) $x $n))))



(declare-top(flonum rz cz a y $t t0 t1 d r1 rp sqrp rnpa r2 ta rn rl rnp rr cr rs cs rlam
		 clam qlam s phi rsum csum)
	 (fixnum n k1 k m mpo ln l ind)
	 (notype ($bessel notype notype) (bessel flonum flonum flonum))
	 (array* (flonum rj-bessel-array 1. cj-bessel-array 1.)
		 (notype $besselarray 1.))
	 (*fexpr $array))

;; Bessel function of the first kind for real or complex arg and real
;; non-negative order.
(defun $bessel ($arg $order)
  (let ((a (float $order)))
    (cond ((not (and (numberp $order)
		     (not (< a 0.0))
		     (numberp ($realpart $arg))
		     (numberp ($imagpart $arg))))
	   ;; Args aren't numeric.  Return unevaluated.
	   (list '($bessel simp) $arg $order))
	  ((zerop ($imagpart $arg))
	   ;; We have numeric args and the first arg is purely
	   ;; real. Call the real-valued Bessel function.  (Should we
	   ;; try calling j0 and j1 as appropriate instead of jn?)
	   (multiple-value-bind (n alpha)
	       (floor (float $order))
	     (let ((jvals (make-array (1+ n) :element-type 'double-float)))
	       (slatec:dbesj (float $arg) alpha (1+ n) jvals 0)
	       (narray $besselarray $float n)
	       (fillarray (nsymbol-array '$besselarray) jvals)
	       (aref jvals n))))
	  (t
	   ;; The first arg is complex.  Use the complex-valued Bessel
	   ;; function
	   (multiple-value-bind (n alpha)
	       (floor (float $order))
	     (let ((cyr (make-array (1+ n) :element-type 'double-float))
		   (cyi (make-array (1+ n) :element-type 'double-float)))
	       (multiple-value-bind (v-zr v-zi v-fnu v-kode v-n
					  v-cyr v-cyi v-nz v-ierr)
		   (slatec:zbesj (float ($realpart $arg))
				 (float ($imagpart $arg))
				 alpha
				 1
				 (1+ n)
				 cyr
				 cyi
				 0
				 0)
		 (declare (ignore v-zr v-zi v-fnu v-kode v-n
				  v-cyr v-cyi v-nz))

		 ;; Should check the return status in v-ierr of this
		 ;; routine.
		 (when (plusp v-ierr)
		   (format t "zbesj ierr = ~A~%" v-ierr))
		 (narray $besselarray $complete (1+ n))
		 (dotimes (k (1+ n)
			   (arraycall 'flonum (nsymbol-array '$besselarray) n))
		   (setf (arraycall 'flonum (nsymbol-array '$besselarray) k)
			 (simplify (list '(mplus)
					 (simplify (list '(mtimes)
							 '$%i
							 (aref cyi k)))
					 (aref cyr k))))))))))))

(defun $bessel_j (arg order)
  (if (and (numberp order)
	   (numberp ($realpart arg))
	   (numberp ($imagpart arg)))
      ($bessel (complex ($realpart arg) ($imagpart arg)) order)
      (subfunmakes '$bessel_j (ncons order) (ncons arg))))

;; Bessel function of the second kind, Y[n](z), for real or complex z
;; and non-negative real n.
(defun bessel-y (arg order)
  (cond ((zerop (imagpart arg))
	 ;; We have numeric args and the first arg is purely
	 ;; real. Call the real-valued Bessel function.  We call j0
	 ;; and j1 instead of jn, if possible.
	 (let ((arg (realpart arg)))
	   (cond ((zerop order)
		  (slatec:dbesy0 arg))
		 ((= order 1)
		  (slatec:dbesy1 arg))
		 (t
		  (multiple-value-bind (n alpha)
		      (floor (float order))
		    (let ((jvals (make-array (1+ n) :element-type 'double-float)))
		      (slatec:dbesy (float (realpart arg)) alpha (1+ n) jvals)
		      (narray $besselarray $float n)
		      (fillarray (nsymbol-array '$besselarray) jvals)
		      (aref jvals n)))))))
	(t
	 ;; The first arg is complex.  Use the complex-valued Bessel
	 ;; function
	 (multiple-value-bind (n alpha)
	     (floor (float order))
	   (let ((cyr (make-array (1+ n) :element-type 'double-float))
		 (cyi (make-array (1+ n) :element-type 'double-float))
		 (cwrkr (make-array (1+ n) :element-type 'double-float))
		 (cwrki (make-array (1+ n) :element-type 'double-float)))
	     (multiple-value-bind (v-zr v-zi v-fnu v-kode v-n
					v-cyr v-cyi v-nz
					v-cwrkr v-cwrki v-ierr)
		 (slatec::zbesy (float (realpart arg))
				(float (imagpart arg))
				alpha
				1
				(1+ n)
				cyr
				cyi
				0
				cwrkr
				cwrki
				0)
	       (declare (ignore v-zr v-zi v-fnu v-kode v-n
				v-cyr v-cyi v-cwrkr v-cwrki))

	       ;; We should check for errors here based on the
	       ;; value of v-ierr.
	       (when (plusp v-ierr)
		 (format t "zbesy ierr = ~A~%" v-ierr))
	       (narray $besselarray $complete (1+ n))
	       (dotimes (k (1+ n)
			 (arraycall 'flonum (nsymbol-array '$besselarray) n))
		 (setf (arraycall 'flonum (nsymbol-array '$besselarray) k)
		       (simplify (list '(mplus)
				       (simplify (list '(mtimes)
						       '$%i
						       (aref cyi k)))
				       (aref cyr k)))))))))))

(defun $bessel_y (arg order)
  (if (and (numberp order)
	   (numberp ($realpart arg))
	   (numberp ($imagpart arg)))
      (bessel-y (complex ($realpart arg) ($imagpart arg)) order)
      (subfunmakes '$bessel_y (ncons order) (ncons arg))))

(declare-top(flonum rz y rs cs third sin60 term sum fi cossum sinsum sign (airy flonum)))

;here is Ai'
;airy1(z):=if z = 0. then -1/(gamma(1/3.)*3.^(1/3.))
;else block([zz],z:-z,zz:2./3.*z^(3./2.),bessel(zz,4./3.),
;j:realpart(2/(3.*zz)*besselarray[0]-besselarray[1]),
;-1/3.*z*(j-realpart(bessel(zz,2./3.))));

(defun $airy ($arg)
  (cond ((numberp $arg)
	 (slatec:dai (float $arg)))
	(t
	 (list '($airy simp) $arg))))

(declare-top (flonum im re ys xs y x c t2 t1 s2 s1 s r2 r1 lamb h2 h)
	 (fixnum np1 n nu capn)
	 (notype (z-function flonum flonum))) 

(defun z-function (x y) 
       ((lambda (xs ys capn nu np1 h h2 lamb r1 r2 s s1 s2 t1 t2 c bool re im) 
		(setq xs (cond ((> 0.0 x) -1.0) (t 1.0)))
		(setq ys (cond ((> 0.0 y) -1.0) (t 1.0)))
		(setq x (abs x) y (abs y))
		(cond ((and (> 4.29 y) (> 5.33 x))
		       (setq s (*$ (1+$ (*$ -0.23310023 y))
				   (sqrt (1+$ (*$ -0.035198873 x x)))))
		       (setq h (*$ 1.6 s) h2 (*$ 2.0 h) capn (f+ 6. (fix (*$ 23.0 s))))
		       (setq nu (f+ 9. (fix (*$ 21.0 s)))))
		      (t (setq h 0.0) (setq capn 0.) (setq nu 8.)))
		(and (> h 0.0) (setq lamb (^$ h2 capn)))
		(setq bool (or (= h 0.0) (= lamb 0.0)))
		(do ((n nu (f1- n)))
		    ((> 0. n))
		    (setq np1 (f1+ n))
		    (setq t1 (+$ h (*$ (float np1) r1) y))
		    (setq t2 (-$ x (*$ (float np1) r2)))
		    (setq c (//$ 0.5 (+$ (*$ t1 t1) (*$ t2 t2))))
		    (setq r1 (*$ c t1) r2 (*$ c t2))
		    (cond ((and (> h 0.0) (not (< capn n)))
			   (setq t1 (+$ s1 lamb) s1 (-$ (*$ r1 t1) (*$ r2 s2)))
			   (setq s2 (+$ (*$ r1 s2) (*$ r2 t1)) lamb (//$ lamb h2)))))
		(setq im (cond ((= y 0.0) (*$ 1.77245384 (exp (-$ (*$ x x)))))
			       (t (*$ 2.0 (cond (bool r1) (t s1))))))
		(setq re (*$ -2.0 (cond (bool r2) (t s2))))
		(cond ((> ys 0.0) (setq re (*$ re xs)))
		      (t (setq r1 (*$ 3.5449077 (exp (-$ (*$ y y) (*$ x x)))))
			 (setq r2 (*$ 2.0 x y))
			 (setq re (*$ (-$ re (*$ r1 (sin r2))) xs))
			 (setq im (-$ (*$ r1 (cos r2)) im))))
		(list '(mlist simp) re im))
	(cond ((> 0.0 x) -1.0) (t 1.0))
	(cond ((> 0.0 x) -1.0) (t 1.0))
	0. 0. 0. 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 nil 0.0 0.0)) 

(defun $nzeta ($z) 
  (prog ($x $y $w) 
	(cond ((and (numberp (setq $x ($realpart $z)))
		    (numberp (setq $y ($imagpart $z))))
	       (setq $w (z-function (float $x) (float $y)))
	       (return (simplify (list '(mplus)
				       (simplify (list '(mtimes)
						       (meval1 '$%i)
						       (caddr $w)))
				       (cadr $w)))))
	      (t (return (list '($nzeta simp) $z))))))


(defun $nzetar ($z)
  (prog ($x $y $w) 
	(cond ((and (numberp (setq $x ($realpart $z)))
		    (numberp (setq $y ($imagpart $z))))
	       (setq $w (z-function (float $x) (float $y)))
	       (return (cadr $w)))
	      (t (return (list '($nzetar simp) $z))))))


(defun $nzetai ($z)
  (prog ($x $y $w) 
	(cond ((and (numberp (setq $x ($realpart $z)))
		    (numberp (setq $y ($imagpart $z))))
	       (setq $w (z-function (float $x) (float $y)))
	       (return (caddr $w)))
	      (t (return (list '($nzetai simp) $z))))))


(declare-top (fixnum i) (flonum (gauss) te)) 

(defun gauss nil
  (do ((i 0. (f1+ i))
       ;;are these random numbers supposed to be negative too?
       (te 0.0 (+$ te (*$ (float (random #+cl most-positive-fixnum
					 #-cl #. (^ 2 30))) 1.45519152e-11))))
      ((= i 12.) te)))


(defun $gauss ($mean $sd)
  (cond ((and (numberp $mean) (numberp $sd))
	 (+$ (float $mean) (*$ (float $sd) (gauss))))
	(t (list '($gauss simp) $mean $sd))))


(declare-top (flonum x w y (expint flonum)))

;; I think this is the function E1(x).  At least some simple numerical
;; tests show that this expint matches the function de1 from SLATEC

;; Exponential integral E1(x).  The Cauchy principal value is used for
;; negative x.
(defun $expint (x)
  (cond ((numberp x)
	 (values (slatec:de1 (float x))))
	(t
	 (list '($expint simp) x))))


;; Define the Bessel funtion J[n](z)

(defprop $bessel_j bessel-j-simp specsimp)

;; If E is a maxima ratio with a denominator of DEN, return the ratio
;; as a Lisp rational.  Otherwise NIL.
(defun max-numeric-ratio-p (e den)
  (if (and (listp e)
	   (eq 'rat (caar e))
	   (= den (third e))
	   (integerp (second e)))
      (/ (second e) (third e))
      nil))

;; Compute the Bessel function of half-integral order.
;;
;; ARG is the argument of the Bessel function
;; ORDER is the order, which must be half of an odd integer
;; 
(defun bessel-half-order (arg order pos-function neg-function)
  ;; The description given here is for J functions, but they equally
  ;; apply to other Bessel functions.
  ;;
  ;; J[n+1/2](z) and J[-n-1/2](z) can be expressed in
  ;; terms of elementary functions.  See A&S 9.1.30.
  ;;
  ;; We have
  ;;
  ;;   J[1/2](z) = sqrt(2/%pi)*sin(z)/sqrt(z)
  ;;
  ;; and
  ;;   J[-1/2](z) = sqrt(2/%pi)*cos(z)/sqrt(z)
  ;;
  (cond ((plusp order)
	 ;; Setting v = 1/2 in the second formula of A&S 9.1.30 we have
	 ;;
	 ;; J[n+1/2](z) = (-1)^n * sqrt(z)*diff(1/sqrt(z)*J[1/2](z), z, n)
	 ;;
	 ;; or, using the expressin for J[1/2](z) above:
	 ;;
	 ;; J[n+1/2](z) = (-1)^n * sqrt(z) * sqrt(2/%pi) *
	 ;;                    diff(sin(z)/z,z,n)
	 ;;
	 (let* ((n (floor order))
		(var (gensym))
		;; deriv = diff(sin(z)/z,z,n)
		(deriv (subst arg var
			      ($diff `((mtimes simp)
				       ((mexpt simp) ,var -1)
				       ((,pos-function simp) ,var))
				     var
				     n))))
	   (simplify `((mtimes)
		       ((mexpt) 2 ((rat) 1 2))
		       ((mexpt) $%pi ((rat) -1 2))
		       ((mexpt) -1 ,n)
		       ((mexpt) ,arg ((rat) 1 2))
		       ,deriv))))
	(t
	 ;; We use the first formula and J[-1/2](z) above to get
	 ;;
	 ;; J[-n-1/2](z) = sqrt(z) * sqrt(2/%pi) *
	 ;;                    diff(cos(z)/z, z, n);
	 (let* ((n (floor (- order)))
		(var (gensym))
		;; deriv = diff(cos(z)/z,z,n)
		(deriv (subst arg var
			      ($diff `((mtimes simp)
				       ((mexpt simp) ,var -1)
				       ((,neg-function simp) ,var))
				     var
				     n))))
	   (simplify `((mtimes)
		       ((mexpt) 2 ((rat) 1 2))
		       ((mexpt) $%pi ((rat) -1 2))
		       ((mexpt) ,arg ((rat) 1 2))
		       ,deriv))))))

(defun bessel-j-simp (exp ignored z)
  (declare (ignore ignored))
  (let ((order (simpcheck (car (subfunsubs exp)) z)))
    (subargcheck exp 1 1 '$bessel_j)
    (let* ((arg (simpcheck (car (subfunargs exp)) z))
	   (real-arg ($realpart arg))
	   (imag-arg ($imagpart arg)))
      (cond ((numberp order)
	     (cond ((or (and (floatp real-arg) (numberp imag-arg))
			(and $numer (numberp real-arg) (numberp imag-arg)))
		    ;; Numerically evaluate it if the arg is a float
		    ;; or if the arg is a number and $numer is
		    ;; non-NIL.
		    ($bessel arg order))
		   ((minusp order)
		    ;; A&S 9.1.5
		    ;; J[-n](x) = (-1)^n*J[n](x)
		    (if (evenp order)
			(subfunmakes '$bessel_j (ncons (- order)) (ncons arg))
			`((mtimes simp) -1 ,(subfunmakes '$bessel_j (ncons (- order)) (ncons arg)))))
		   (t
		    (eqtest (subfunmakes '$bessel_j (ncons order) (ncons arg))
			    exp))))
	    ((setq order (max-numeric-ratio-p order 2))
	     ;; When order is a fraction with a denominator of 2, we
	     ;; can express the result in terms of elementary
	     ;; functions.
	     ;;
	     ;; J[1/2](z) is a function of sin.  J[-1/2](z) is a
	     ;; function of cos.
	     (bessel-half-order arg order '%sin '%cos))
	    (t
	     (eqtest (subfunmakes '$bessel_j (ncons order) (ncons arg))
		     exp))))))


;; Define the Bessel funtion Y[n](z)

(defprop $bessel_y bessel-y-simp specsimp)

#+nil
(defun bessel-y-simp (exp ignored z)
  (declare (ignore ignored))
  (let ((order (simpcheck (car (subfunsubs exp)) z)))
    (subargcheck exp 1 1 '$bessel_y)
    (let* ((arg (simpcheck (car (subfunargs exp)) z))
	   (real-arg ($realpart arg))
	   (imag-arg ($imagpart arg)))
      ;;(format t "order = ~A~%" order)
      ;;(format t "arg   = ~A (~A ~A)~%" arg real-arg imag-arg)
      (cond ((and (numberp order)
		  (numberp real-arg) (floatp real-arg)
		  (numberp imag-arg))
	     ;; Numerically evaluate it
	     (bessel-y (complex ($realpart arg) ($imagpart arg)) order))
	    (t
	     (eqtest (subfunmakes '$bessel_y (ncons order) (ncons arg))
		     exp))))))

(defun bessel-y-simp (exp ignored z)
  (declare (ignore ignored))
  (let ((order (simpcheck (car (subfunsubs exp)) z)))
    (subargcheck exp 1 1 '$bessel_y)
    (let* ((arg (simpcheck (car (subfunargs exp)) z))
	   (real-arg ($realpart arg))
	   (imag-arg ($imagpart arg)))
      (cond ((numberp order)
	     (cond ((or (and (floatp real-arg) (numberp imag-arg))
			(and $numer (numberp real-arg) (numberp imag-arg)))
		    ;; Numerically evaluate it if the arg is a float
		    ;; or if the arg is a number and $numer is
		    ;; non-NIL.
		    (bessel-y (complex real-arg imag-arg) (float order)))
		   ((minusp order)
		    ;; A&S 9.1.5
		    ;; Y[-n](x) = (-1)^n*Y[n](x)
		    (if (evenp order)
			(subfunmakes '$bessel_y (ncons (- order)) (ncons arg))
			`((mtimes simp) -1 ,(subfunmakes '$bessel_y (ncons (- order)) (ncons arg)))))
		   (t
		    (eqtest (subfunmakes '$bessel_y (ncons order) (ncons arg))
			    exp))))
	    ((setq order (max-numeric-ratio-p order 2))
	     ;; When order is a fraction with a denominator of 2, we
	     ;; can express the result in terms of elementary
	     ;; functions.
	     ;;
	     ;; Y[1/2](z) = -J[1/2](z) is a function of sin.
	     ;; Y[-1/2](z) = -J[-1/2](z) is a function of cos.
	     (simplify `((mtimes) -1 ,(bessel-half-order arg order '%sin '%cos))))
	    (t
	     (eqtest (subfunmakes '$bessel_y (ncons order) (ncons arg))
		     exp))))))

;; Define the Bessel funtion I[n](z)

(defprop $bessel_i bessel-i-simp specsimp)

#+nil
(defun bessel-i-simp (exp ignored z)
  (declare (ignore ignored))
  (let ((order (simpcheck (car (subfunsubs exp)) z)))
    (subargcheck exp 1 1 '$bessel_i)
    (let* ((arg (simpcheck (car (subfunargs exp)) z))
	   (real-arg ($realpart arg))
	   (imag-arg ($imagpart arg)))
      ;;(format t "order = ~A~%" order)
      ;;(format t "arg   = ~A (~A ~A)~%" arg real-arg imag-arg)
      (cond ((and (numberp order)
		  (numberp real-arg) (floatp real-arg)
		  (numberp imag-arg))
	     ;; Numerically evaluate it
	     ($in arg order))
	    (t
	     (eqtest (subfunmakes '$bessel_i (ncons order) (ncons arg))
		     exp))))))

(defun bessel-i-simp (exp ignored z)
  (declare (ignore ignored))
  (let ((order (simpcheck (car (subfunsubs exp)) z)))
    (subargcheck exp 1 1 '$bessel_i)
    (let* ((arg (simpcheck (car (subfunargs exp)) z))
	   (real-arg ($realpart arg))
	   (imag-arg ($imagpart arg)))
      (cond ((numberp order)
	     (cond ((or (and (floatp real-arg) (numberp imag-arg))
			(and $numer (numberp real-arg) (numberp imag-arg)))
		    ;; Numerically evaluate it if the arg is a float
		    ;; or if the arg is a number and $numer is
		    ;; non-NIL.
		    (bessel-i (complex real-arg imag-arg) (float order)))
		   ((minusp order)
		    ;; A&S 9.6.6
		    ;; I[-n](x) = I[n](x)
		    (subfunmakes '$bessel_i (ncons (- order)) (ncons arg)))
		   (t
		    (eqtest (subfunmakes '$bessel_i (ncons order) (ncons arg))
			    exp))))
	    ((setq order (max-numeric-ratio-p order 2))
	     ;; When order is a fraction with a denominator of 2, we
	     ;; can express the result in terms of elementary
	     ;; functions.
	     ;;
	     ;; I[1/2](z) = sqrt(2/%pi/z)*sinh(z)
	     ;; I[-1/2](z) = sqrt(2/%pi/z)*cosh(z)
	     (bessel-half-order arg order '%sinh '%cosh))
	    (t
	     (eqtest (subfunmakes '$bessel_i (ncons order) (ncons arg))
		     exp))))))
