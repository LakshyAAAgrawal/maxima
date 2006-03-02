;;; -*-  Mode: Lisp; Package: Maxima; Syntax: Common-Lisp; Base: 10 -*- ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     The data in this file contains enhancments.                    ;;;;;
;;;                                                                    ;;;;;
;;;  Copyright (c) 1984,1987 by William Schelter,University of Texas   ;;;;;
;;;     All rights reserved                                            ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     (c) Copyright 1982 Massachusetts Institute of Technology         ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :maxima)
(macsyma-module irinte)
(load-macsyma-macros rzmac)

(declare-top (special checkcoefsignlist
		      #+nil ec-1
		      #+nil r12
		      #+nil 1//2
		      var
		      #+nil globalcareflag
		      zerosigntest productcase $radexpand))

(defun hasvar (exp) (not (freevar exp)))

(defun zerp (a) (equal a 0))

(defun integerpfr (a) (if (not (maxima-integerp a)) (integerp1 a)))

(defun nonzerp (a) (not (equal a 0)))

(defun freevnz (a) (and (freevar a) (not (equal a 0))))

(defun inte (funct x)
  (prog (checkcoefsignlist *globalcareflag* $radexpand)
     (declare (special *globalcareflag*))
     (setq $radexpand t)
     (return (intir-ref funct x))))

(defun intir-ref (fun x)
  (prog (a)
     (cond ((setq a (intir1 fun x))(return a)))
     (cond ((setq a (intir2 fun x))(return a)))
     (return (intir3 fun x))))

(defun intir1 (fun x)
  (prog (assoclist e0 r0 e1 e2 r1 r2 d p)
     (setq assoclist (factpow (specrepcheck fun) x))
     (setq e1 (cdras 'e1 assoclist)
	   e2 (cdras 'e2 assoclist))
     (cond ((null assoclist)(return nil)))
     (setq d (cdras 'd assoclist)
	   p (cdras 'p assoclist)
	   e0 (cdras 'e0 assoclist)
	   r0 (cdras 'r0 assoclist)
	   r1 (cdras 'r1 assoclist)
	   r2 (cdras 'r2 assoclist))
     (cond ((floatp e0)
	    (setq e0 (rdis (ration1 e0)))))
     (cond ((floatp e1)
	    (setq e1 (rdis (ration1 e1)))))
     (cond ((floatp e2)
	    (setq e2 (rdis (ration1 e2)))))
     (return (intir1-ref d p r0 e0 r1 e1 r2 e2 x))))

(defun intir2 (funct x)
  (prog (res)
     (cond ((setq res (intir funct x))(return res)))
     (return (intirfactoroot funct x))))

(defun intir3 (exp x)
  (prog (assoclist e f g r0)
     (cond ((setq assoclist (elliptquad exp x))
	    (setq e (cdras 'e assoclist) f (cdras 'f assoclist)
		  g (cdras 'g assoclist) r0 (cdras 'r0 assoclist))
	    (assume `(($notequal) ,e 0))
	    (return (intir3-r0test assoclist x e f g r0))))
     (return nil)))

(defun intir3-r0test (assoclist x e f g r0)
  (cond ((root+anything r0 x) nil)
	(t (intir3-ref assoclist x e f g r0))))

;; Handle integrals of the form d*p(x)*r1(x)^e1*r2(x)^e2*r0(x)^e0,
;; where p(x) is a polynomial, e1 and e2 are both half an odd integer,
;; and e3 is an integer.
(defun intir1-ref (d p r0 e0 r1 e1 r2 e2 x)
  ((lambda (nume1 nume2)
     ;; nume1 = 2*e1
     ;; nume2 = 2*e2


     ;; I think what this does is try to rationalize r1(x)^e1 or
     ;; r2(x)^e2 so we end up with a new integrand of the form
     ;; d*p'(x)*r0'(x)^e0*ra(x)^ea, where p'(x) is a new polynomial
     ;; obtained from rationaling one term and r0'(x) is a more
     ;; complicated term.
     (cond ((and (plusp nume1)
		 (plusp nume2))
	    (pp-intir1 d p r0 e0 r1 e1 r2 e2 x))
	   ((and (minusp nume1)
		 (minusp nume2))
	    (mm-intir1 d p r0 e0 r1 e1 r2 e2 x))
	   ((plusp nume1)
	    (pm-intir1 d p r0 e0 r1 e1 r2 e2 x))
	   (t
	    (pm-intir1 d p r0 e0 r2 e2 r1 e1 x))))
   (cadr e1)
   (cadr e2)))

(defun pp-intir1 (d p r0 e0 r1 e1 r2 e2 x)
  ((lambda (nume1 nume2)
     (cond ((greaterp nume1 nume2)(pp-intir1-exec d p r0 e0 r1 e1 r2 e2 x))
	   (t (pp-intir1-exec d p r0 e0 r2 e2 r1 e1 x))))
   (cadr e1) (cadr e2)))


;; Handle integrals of the form d*p(x)*r0(x)^e0*r1(x)^e1*r2(x)^e2
;; where p(x) is a polynomial, e1 < 0, and e2 < 0 and are both half an
;; odd integer, and e3 is an integer.
(defun mm-intir1 (d p r0 e0 r1 e1 r2 e2 x)
  ((lambda (nume1 nume2)
     (cond ((greaterp nume1 nume2)
	    (mm-intir1-exec d p r0 e0 r1 e1 r2 e2 x))
	   (t (mm-intir1-exec d p r0 e0 r2 e2 r1 e1 x))))
   (cadr e1) (cadr e2)))

;; Handle integrals of the form d*p(x)*r0(x)^e0*r1(x)^e1*r2(x)^e2
;; where p(x) is a polynomial, e1 > 0, and e2 < 0 and are both half an
;; odd integer, and e3 is an integer.
;;
(defun pm-intir1 (d p r0 e0 rofpos epos rofneg eneg x)
  ((lambda (numepos numul-1eneg)
     ;; numepos = 2*epos = 2*e1
     ;; numul-1eneg = -2*eneg = -2*e2
     (cond ((greaterp numepos numul-1eneg)
	    (mm-intir1 d (mul p (power rofpos (sub epos eneg)))
		       r0 e0 rofpos eneg rofneg eneg x))
	   ((or (equal e0 0)
		(plusp e0))
	    (pp-intir1 d (mul p (power rofneg (sub eneg epos)))
		       r0 e0 rofpos epos rofneg epos x))
	   (t (mm-intir1 d (mul p (power rofpos (sub epos eneg)))
			 r0 e0 rofpos eneg rofneg eneg x))))
   (cadr epos)
   (mul -1 (cadr eneg))))

(defun pp-intir1-exec (d p r0 e0 rofmax emax rofmin emin x)
  (intir (mul d p (cond ((equal e0 0) 1) (t (power r0 e0)))
	      (power rofmax (add emax (mul -1 emin)))
	      (power ($expand (mul rofmax rofmin)) emin)) x))

;; Handle integrals of the form d*p(x)*r0(x)^e0*r1(x)^e1*r2(x)^e2
;; where p(x) is a polynomial, e1 < 0, and e2 < 0 and are both half an
;; odd integer, and e3 is an integer.  And e2 > e1.
(defun mm-intir1-exec (d p r0 e0 rofmin emin rofmax emax x)
  (intir (mul d p
	      (cond ((equal e0 0) 1)
		    (t (power r0 e0)))
	      (power rofmax (add emax (mul -1 emin)))
	      (power ($expand (mul rofmax rofmin)) emin)) x))

;; Integrating the form (e*x^2+f*x+g)^m*r0(x)^e0.
#+nil
(defun intir3-ref (assoclist x e f g r0)
  ((lambda (signdisc d p e0)
     (cond ((or (eq signdisc '$positive)
		(eq signdisc '$negative))
	    (pns-intir3 x e f g d p r0 e0))
	   (t (zs-intir3 x e f d p r0 e0))))
   (signdiscr e f g)
   (cdras 'd assoclist)
   (cdras 'p assoclist)
   (cdras 'e0 assoclist)))

(defun intir3-ref (assoclist x e f g r0)
  ((lambda (signdisc d p e0)
     (cond ((eq signdisc '$positive)
	    (pns-intir3 x e f g d p r0 e0))
	   ((eq signdisc '$negative)
	    (ns-intir3 x e f g d p r0 e0))
	   (t (zs-intir3 x e f d p r0 e0))))
   (signdiscr e f g)
   (cdras 'd assoclist)
   (cdras 'p assoclist)
   (cdras 'e0 assoclist)))

(defun root+anything (exp var)
  (m2 exp '((mplus)
	    ((coeffpt) (c nonzerp) ((mexpt) (u hasvar) (v integerpfr)))
	    ((coeffpp) (c true))) nil))

;; Handle d*p(x)/(e*x^2+f*x+g)*r0(x)^e0.  We know that e*x^2+f*x+g has
;; no repeated roots.  Let D be the discriminant of this quadratic,
;; sqrt(f^2-4*e*g).  Thus, we can factor this quadratic as
;; (2*e*x+f-D)*(2*e*x+f+D)/(4*e^2).  Thus, the original integrand becomes
;;
;; 4*e^2*d/(2*e*x+f-D)/(2*e*x+f+D)*p(x)*r0(x)^e0.
;;
;; We can separate this as a partial fraction to get
;;
;; (2*d*e^2/D/(2*e*x+f-D) - 2*d*e^2/D/(2*e*x+f+D))*p(x)*r0(x)^e0.
;;
;; So we have separated this into two "simpler" integrals.
(defun pns-intir3 (x e f g d p r0 e0)
  ((lambda (discr)
     ((lambda (p*r0^e0 2*e*x+f 2*e^2*d*invdisc)
	(mul 2*e^2*d*invdisc
	     (sub (intir2 (mul (inv (sub 2*e*x+f discr))
			       p*r0^e0)
			  x)
		  (intir2 (mul (inv (add 2*e*x+f discr))
			       p*r0^e0)
			  x))))
      (mul p (power r0 e0))
      (add (mul 2 e x) f)
      (mul 2 e e d (inv discr))))
   ;; Compute discriminant of quadratic:  sqrt(f^2-4*e*g)
   (power (sub (mul f f) (mul 4 e g)) (inv 2))))

;; Handle d*p(x)/(e*x^2+f*x+g)*r0(x)^e0.  We know that e*x^2+f*x+g has
;; repeated roots.
;;
(defun zs-intir3 (x e f d p r0 e0)
  ;; Since e*x^2+f*x+g has repeated roots, it can be written as e*(x+r)^2.
  ;; We easily see that r = f/(2*e), so rewrite the integrand as
  ;;
  ;; d*p(x)/e/(x-r)^2*r0(x)^e0.
  (intir2 (mul d p (inv e)
	       (power (add x (div f (add e e))) -2)
	       (power r0 e0))
	  x))

;; Handle d*p(x)/(e*x^2+f*x+g)*r0(x)^e0.  We know that e*x^2+f*x+g has
;; no real roots.
;;
;; G&R 2.252 shows how we can handle these integrals, but I'm too lazy
;; to implement them right now, so return NIL to indicate we don't
;; know what to do.  But whatever it is we do, it's definitely not
;; calling intir or intir2 like zs-intir3 or pns-intir3 do because
;; they eventually call inti which only handles linear forms (e = 0.)
;; We'll need to write custom versions.
(defun ns-intir3 (x e f g d p r0 e0)
  (declare (ignore x e f g d p r0 e0))
  nil)

(defun cdras (a b)
  (cdr (zl-assoc a b)))

(defun intir (funct x)
  (prog (assoclist)
     (setq assoclist (jmaug (specrepcheck funct) x))
     (return (inti funct x assoclist))))

;; Integrate d*p(x)*(f*x+e)^m*(a*x^2+b*x+c)^n.  p(x) is a polynomial,
;; m is an integer, n is a number(?).  a, b, c, e, and f are
;; expressions independent of x (var).
(defun inti (funct x assoclist)
  (prog (met n expr f e denom)
     (setq n (cdras 'n assoclist))
     (cond ((or (null assoclist) (maxima-integerp n))
	    (return nil)))
     (setq f (cdras 'f assoclist)
	   e (cdras 'e assoclist))
     ;; If e is 0 (or not given, we don't have to do the
     ;; transformation.  Just integrate it and return.
     (cond ((or (equal e 0) (null e))
	    (return (intira funct x))))
     (cond ((not (numberp f)) (go jump)))
     (cond ((plusp f)(go jump)))
     ;; I (rtoy) think this is the case where f is a negative number.
     ;; I think this is trying to convert f*x+e to -f*x-e to make the
     ;; coefficient of x positive.  And if I'm right, the code below
     ;; isn't doing it correctly, except when m = 1 or m = -1.
     #+nil
     (setq denom (add (mul f x) e)
	   f (mul -1 f)
	   e (mul -1 e)
	   funct (mul -1 (div (meval (mul denom funct))
			      (add (mul f x) e))))
     jump
     ;; Apply the linear substitution y = f*x+e.  That is x = (y-e)/f.
     ;; Then use INTIRA to integrate this.  The integrand becomes
     ;; something like p(y)*y^m and other terms.
     (setq expr
	   (mul (power f -1)
		(intira (distrexpandroot
			 (cdr ($substitute
			       (mul (power f -1)
				    (add (setq met
					       (make-symbol
						"YANNIS")
					       )
					 (mul -1 e)))
			       x funct)))
			met)))
     (return ($expand ($substitute (add (mul f x) e) met expr)))))

(defun distrexpandroot (expr)
  (cond ((null expr) 1)
	(t (mul (expandroot (car expr))
		(distrexpandroot (cdr expr))))))

(defun expandroot (expr)
  (cond ((atom expr) expr)
	(t (cond ((and (eq (caar expr) 'mexpt)
		       (integerpfr (caddr expr)))
		  ($expand expr))
		 (t expr)))))

(defun intirfactoroot (expr x)
  (declare (special *globalcareflag*))
  (prog (assoclist exp)
     (setq exp expr)
     (cond ((setq assoclist (jmaug (setq expr (distrfactor (timestest expr) x)) x))
	    (return (inti expr x assoclist))))
     (setq *globalcareflag* 't)
     (cond ((setq assoclist (jmaug (setq exp (distrfactor (timestest exp) x)) x))
	    (setq *globalcareflag* nil)
	    (return (inti exp x assoclist))))
     (setq *globalcareflag* nil)
     (return nil)))

(defun distrfactor (expr x)
  (cond ((null expr) 1)
	(t (mul (factoroot (car expr) x)
		(distrfactor (cdr expr) x)))))

(defun factoroot (expr var)
  (cond ((atom expr) expr)
	(t (cond ((and (eq (caar expr) 'mexpt)
		       (hasvar expr)
		       (integerpfr (caddr expr)))
		  (carefulfactor expr var))
		 (t expr)))))

(defun carefulfactor (expr x)
  (declare (special *globalcareflag*))
  (cond ((null *globalcareflag*)($factor expr))
	(t (restorex ($factor (power (div (cadr expr) x) (caddr expr))) x))))

(defun restorex (expr var)
  (cond ((atom expr) expr)
	(t (cond ((eq (caar expr) 'mtimes)
		  (distrestorex (cdr expr) var))
		 (t expr)))))

(defun distrestorex (expr var)
  (cond ((null expr) 1)
	(t (mul (restoroot (car expr) var)
		(distrestorex (cdr expr) var)))))

(defun restoroot (expr var)
  (cond ((atom expr) expr)
	(t (cond ((and (eq (caar expr) 'mexpt)
		       (integerpfr (caddr expr))
		       (mplusp (cadr expr)))
		  (power ($expand (mul var (cadr expr))) (caddr expr)))
		 (t expr)))))

(defun timestest (expr)
  (cond ((atom expr)(list expr))
	(t (cond ((eq (caar expr) 'mtimes)(cdr expr))
		 (t (list expr))))))

;; Integrate a function of the form d*p(y)*y^m*(a*y^2+b*x+c)^n.
;; n is half of an integer.
(defun intira (funct x)
  (prog (a b c *ec-1* d m n assoclist pluspowfo1 pluspowfo2 minuspowfo
	   polfact signn poszpowlist negpowlist)
     (declare (special *ec-1*))
     (setq assoclist (jmaug (specrepcheck funct) x))
     (setq n (cdras 'n assoclist))
     ;; r12 1//2)
     ;; (format t "n = ~A~%" n)
     (cond ((or (null assoclist)
		(maxima-integerp n))
	    (return nil)))
     (cond ((floatp n)
	    (setq n (rdis (ration1 n)))))
     (setq d (cdras 'd assoclist))
     (cond ((equal d 0) (return 0)))
     (setq c (cdras 'a assoclist))
     (if (equal c 0) (return nil))
     (setq m (cdras 'm assoclist)
	   polfact (cdras 'p assoclist)
	   ;; We know that n is of the form s/2, so just make n = s,
	   ;; and remember that the actual exponent needs to be
	   ;; divided by 2.
	   n (cadr n)
	   signn (checksigntm n)
	   *ec-1* (power c -1)
	   b (cdras 'b assoclist)
	   a (cdras 'c assoclist)
	   ;; pluspowfo1 = 1/2*(n-1), That is, the original exponent - 1/2.
	   pluspowfo1 (mul 1//2 (plus n -1))
	   ;; minupowfo = 1/2*(n+1), that is, the original exponent + 1/2.
	   minuspowfo (mul 1//2 (plus n 1))
	   ;; pluspowfo2 = -1/2*(n+1), that is, the negative of 1/2
	   ;; plus the original exponent.
	   pluspowfo2 (times -1 minuspowfo))
     (destructuring-bind (pos &optional neg)
	 (powercoeflist polfact m x)
       (setf poszpowlist pos)
       (setf negpowlist neg))

     #+nil
     (progn
       (format t "n = ~A~%" n)
       (format t "pluspowfo1 = ~A~%" pluspowfo1)
       (format t "minuspowfo = ~A~%" minuspowfo)
       (format t "pluspowfo2 = ~A~%" pluspowfo2))
     
     ;; I (rtoy) think powercoeflist computes p(x)/x^m as a Laurent
     ;; series.  POSZPOWLIST is a list of coefficients of the positive
     ;; powers and NEGPOWLIST is a list of the negative coefficients.
     (cond ((and (null negpowlist)
		 (not (null poszpowlist)))
	    ;; Only polynomial parts.
	    (cond ((eq signn '$positive)
		   (return (augmult (mul d
					 (nummnumn poszpowlist
						   pluspowfo1
						   minuspowfo c b a x))))))
	    (return (augmult (mul d
				  (nummdenn poszpowlist
					    pluspowfo2 c b a x))))))
     (cond ((and (null poszpowlist)
		 (not (null negpowlist)))
	    ;; No polynomial parts
	    (cond ((eq signn '$positive)
		   (return (augmult (mul d
					 (denmnumn negpowlist
						   minuspowfo c b a x))))))
	    (return (augmult (mul d
				  (denmdenn negpowlist
					    pluspowfo2 c b a x))))))
     (cond ((and (not (null negpowlist))
		 (not (null poszpowlist)))
	    ;; Positive and negative powers.
	    (cond ((eq signn '$positive)
		   (return (add (augmult (mul d
					      (nummnumn poszpowlist
							pluspowfo1
							minuspowfo c b a x)))
				(augmult (mul d
					      (denmnumn negpowlist
							minuspowfo c b a x)))))))
	    (return (add (augmult (mul d
				       (nummdenn poszpowlist
						 pluspowfo2 c b a x)))
			 (augmult (mul d
				       (denmdenn negpowlist
						 pluspowfo2 c b a x)))))))))

;; Match d*p(x)*(f*x+e)^m*(a*x^2+b*x+c)^n.  p(x) is a polynomial, m is
;; an integer, n is half of an integer.  a, b, c, e, and f are
;; expressions independent of x (var).
(defun jmaug (exp var)
  (m2 exp '((mtimes)
	    ((coefftt) (d freevar))
	    ((coefftt) (p polyp))
	    ((mexpt) ((mplus) ((coeffpt) (f freevar) (x varp))
		      ((coeffpp)(e freevar)))
	     (m maxima-integerp))
	    ((mexpt) ((mplus)
		      ((coeffpt) (a freevar) ((mexpt) (x varp) 2))
		      ((coeffpt) (b freevar) (x varp))
		      ((coeffpp) (c freevar)))
	     (n integerp1)))
      nil))

;; Match d*p(x)*r1(x)^e1*r2(x)^e2*r0(x)^e0, where p(x) is a
;; polynomial, e1 and e2 are both half an odd integer, and e3 is an
;; integer.
(defun factpow (exp var)
  (m2 exp '((mtimes) ((coefftt) (d freevar))
	    ((coefftt) (p polyp))
	    ((mexpt) (r1 hasvar)
	     (e1 integerpfr))
	    ((mexpt) (r2 hasvar)
	     (e2 integerpfr))
	    ((mexpt) (r0 hasvar)
	     (e0 maxima-integerp)))
      nil))

;; Match EXP to the form
;; d*p/(e*x^2+f*x+g)*r0(x)^e0.  p is a polynomial in x.
(defun elliptquad (exp var)
  (m2 exp '((mtimes)
	    ((coefftt) (d freevar))
	    ((coefftt) (p polyp))
	    ((mexpt) ((mplus) ((coeffpt) (e freevnz) ((mexpt) (x varp) 2))
		      ((coeffpt) (f freevar) (x varp))
		      ((coeffpp) (g freevar)))
	     -1)
	    ((mexpt) (r0 hasvar)
	     (e0 integerpfr)))
      nil))

;; From the set of coefficients, generate the polynomial c*x^2+b*x+a.
(defun polfoo (c b a x)
  (add (mul c x x)
       (mul b x)
       a))

;; I think this is computing the list of coefficients of fun(x)/x^m,
;; where fun(x) is a polynomial and m is a non-negative integer.  The
;; result is a list of two lists.  The first list contains the
;; polynomial part of fun(x)/x^m.  The second is the principal part
;; containing negative powers.
;;
;; Each of the lists is itself a list of power and coefficient itself.
;;
;; Thus (x+3)^2/x^2 = 1 + 6/x + 9/x^2 returns
;;
;; '(((0 1)) ((1 6) (2 9)))
(defun powercoeflist (fun m var) 
  (prog (expanfun maxpowfun powfun coef poszpowlist negpowlist) 
     (setq expanfun (unquote ($expand (mul (prevconstexpan fun var)
					   (power var m)))))
     (cond ((and (equal fun 1) (greaterp m 0))
	    (return (cons nil (list (list (cons m (list 1))))))))
     (cond ((and (equal fun 1)(lessp m 0))
	    (return (cons nil (list (list (cons (times -1 m ) (list 1))))))))
     (cond ((equal expanfun 1)
	    (return (cons (list (cons 0 (list 1)))
			  (list nil)))))
     (setq maxpowfun ($hipow expanfun var)
	   powfun ($lopow expanfun var))
     loop (setq coef ($coeff expanfun (power var powfun)))
     (cond ((numberp coef) (go testjump)))
     (go nojump)
     testjump (cond ((and (not (zerop powfun)) (zerop coef))
		     (go jump)))
     nojump   (cond ((greaterp powfun 0)
		     (setq poszpowlist (append poszpowlist
					       (list (cons powfun (list coef)))))))
     (cond ((zerop powfun)
	    (setq poszpowlist
		  (append poszpowlist
			  (list (cons 0 (list (consterm (cdr expanfun) var))))))))
     (cond ((lessp powfun 0)
	    (setq negpowlist (append negpowlist
				     (list (cons (times  -1 powfun)(list coef)))))))
     (cond ((equal powfun maxpowfun)
	    (return (list poszpowlist (reverse negpowlist)))))
     jump (setq powfun (add1 powfun)) (go loop)))

(defun consterm (fun var) 
  (cond ((null fun) 0)
	((freeof var (car fun))
	 (add (car fun) (consterm (cdr fun) var)))
	(t (consterm (cdr fun) var))))

(defun prevconstexpan (fun var) 
  (cond ((atom fun) fun)
	((eq (caar fun) 'mplus)
	 (cond ((and (freeof var fun)
		     (not (inside fun 'mexpt)))
		(list '(mquote) fun))
	       ((and (freeof var fun) (inside fun 'mexpt))
		(list '(mquote)
		      (distrinplusprev (cdr fun) var)))
	       ((inside fun 'mexpt)
		(distrinplusprev (cdr fun) var))
	       (t fun)))
	((eq (caar fun) 'mtimes)
	 (distrintimesprev (cdr fun) var))
	((and (not (inside (cdr fun) var))
	      (eq (caar fun) 'mexpt))
	 (power (prevconstexpan (cadr fun) var) (caddr fun)))
	(t fun)))

(defun distrinplusprev (fun var) 
  (cond ((null fun) 0)
	(t (add (prevconstexpan (car fun) var)
		(distrinplusprev (cdr fun) var))))) 

(defun distrintimesprev (fun var) 
  (cond ((null fun) 1)
	(t (mul (prevconstexpan (car fun) var)
		(distrintimesprev (cdr fun) var))))) 

(defun inside (fun arg)
  (cond ((atom fun)(equal fun arg)) 
	((inside (car fun) arg) t)
	(t (inside (cdr fun) arg))))

(defun unquote (fun) 
  (cond ((not (inside fun 'mquote)) fun)
	(t (unquote (meval fun)))))

(defun checksigntm (expr)
  (prog (aslist quest zerosigntest productcase)
     (setq aslist checkcoefsignlist)
     (cond ((atom expr) (go loop)))
     (cond ((eq (caar expr) 'mtimes)(setq productcase t)))
     loop (cond ((null aslist)
		 (setq checkcoefsignlist
		       (append checkcoefsignlist
			       (list (cons expr
					   (list
					    (setq quest (checkflagandact expr)))))))
		 (return quest)))
     (cond ((equal (caar aslist) expr) (return (cadar aslist))))
     (setq aslist (cdr aslist))
     (go loop)))

(defun checkflagandact (expr)
  (cond (productcase
	 (setq productcase nil)
	 (findsignoftheirproduct (findsignofactors (cdr expr))))
	(t (asksign ($realpart expr)))))

(defun findsignofactors (listofactors)
  (cond ((null listofactors) nil)
	((eq zerosigntest '$zero) '$zero)
	(t (append (list (setq zerosigntest (checksigntm (car listofactors))))
		   (findsignofactors (cdr listofactors))))))

(defun findsignoftheirproduct (llist)
  (prog (sign)
     (cond ((eq llist '$zero) (return '$zero)))
     (setq sign '$positive)
     loop (cond ((null llist) (return sign)))
     (cond ((eq (car llist) '$positive)
	    (setq llist (cdr llist))
	    (go loop)))
     (cond ((eq (car llist) '$negative)
	    (setq sign (changesign sign) llist (cdr llist))
	    (go loop)))
     (return '$zero)))

(defun changesign (sign)
  (cond ((eq sign '$positive) '$negative)
	(t '$positive)))

;; Integrate 1/sqrt(c*x^2+b*x+a).
;;
;; G&R 2.261 gives the following, where R = c*x^2+b*x+a and D =
;; 4*a*b-b^2:
;;
;; c > 0:
;;   1/sqrt(c)*log(2*sqrt(c*R)+2*c*x+b)
;;
;; c > 0, D > 0:
;;   1/sqrt(c)*asinh((2*c*x+b)/sqrt(D))
;;
;; c < 0, D < 0:
;;   -1/sqrt(-c)*asin((2*c*x+b)/sqrt(-D))
;;
;; c > 0, D = 0:
;;   1/sqrt(c)*log(2*c*x+b)
;;
(defun den1 (c b a x)
  ((lambda (expo expr)
     ;; expo = -1/2
     ;; expr = 2*c*x+b
     (prog (signdiscrim signc signb)
	(setq signc (checksigntm (power c -1)))
	(setq signb (checksigntm (power b 2)))
	(setq signdiscrim (signdis2 c b a signc signb))
	(cond ((and (eq signc '$positive)
		    (eq signdiscrim '$negative))
	       ;; c > 0, D > 0
	       (return (augmult (mul* (power  c expo)
				      (list '(%asinh)
					    (mul expr
						 (power (add (mul 4 c a)
							     (mul -1 b b))
							expo))))))))
	(cond ((and (eq signc '$positive)
		    (eq signdiscrim '$zero))
	       ;; c > 0, D = 0
	       (return (augmult (mul* (power -1 expr)
				      (power c expo)
				      (list '(%log) expr))))))
	(cond ((eq signc '$positive)
	       ;; c > 0
	       (return (augmult (mul* (power c expo)
				      (list '(%log)
					    (add (mul 2
						      (power c 1//2)
						      (power
						       (polfoo c b
							       a x)
						       1//2))
						 expr)))))))
	(cond ((and (eq signc '$negative)
		    (eq signdiscrim '$positive))
	       ;; c < 0, D > 0
	       (return (augmult (mul* -1
				      (power (mul -1 c) expo)
				      (list '(%asin)
					    (mul expr
						 (power (add (mul b b)
							     (mul -4 c a))
							expo))))))))
	(cond ((eq signc '$negative)
	       ;; c < 0.  We try again, but flip the sign of the
	       ;; polynomial, and multiply by -%i.
	       (return (augmult (mul (power -1 expo)
				     (den1 (mul -1 c)
					   (mul -1 b)
					   (mul -1 a)
					   x))))))))
   (list '(rat) -1 2)
   (add (mul 2 c x) b)))

;; Compute sign of discriminant of the quadratic c*x^2+b*x+a.  That
;; is, the sign of b^2-4*c*a.
(defun signdiscr (c b a) 
  (checksigntm (simplifya (add (power b 2)
			       (mul -4 c a))
			  nil)))

(defun askinver (a)
  (checksigntm (power a -1)))

(defun signdis1 (c b a)
  (cond ((equal (mul b a) 0)
	 (cond ((and (equal b 0)
		     (equal a 0))
		'$zero)
	       (t '$nonzero)))
	(t
	 ;; Why are we checking the sign of (b^2-4*a*c)^2?
	 (checksigntm (power (add (mul b b) (mul -4 c a)) 2)))))

;; Check sign of discriminant of c*x^2+b*x+a, but also taking into
;; account the sign of c and b.
(defun signdis2 (c b a signc signb)
  (cond ((equal signb '$zero)
	 (cond ((equal a 0) '$zero)
	       (t ((lambda (askinv)
		     (cond ((or (and (eq signc '$positive)
				     (eq askinv '$negative))
				(and (eq signc '$negative)
				     (eq askinv '$positive)))
			    '$positive)
			   (t '$negative)))
		   (askinver a)))))
	(t (cond ((equal a 0) '$positive)
		 (t (signdiscr c b a))))))

(defun signdis3 (c b a signa)
  (declare (special *ec-1*))
  (cond ((equal b 0)
	 (cond ((equal (checksigntm *ec-1*) signa) '$negative)
	       (t '$positive)))
	(t (signdiscr c b a))))

(defun nummnumn (poszpowlist pluspowfo1 p c b a x) 
  (declare (special *ec-1*))
  ((lambda (expr expo ex)
     (prog (result controlpow coef count res1 res2 m partres)
	(setq result 0 controlpow (caar poszpowlist)
	      coef (cadar poszpowlist))
	(cond ((zerop controlpow)
	       (setq result (augmult (mul coef (numn pluspowfo1 c b a x)))
		     count 1)
	       (go loop)))
	jump1 (setq res1 (add (augmult (mul expr expo
					    (power (plus p p 1) -1)))
			      (augmult (mul -1 b 1//2 expo
					    (numn pluspowfo1 c b a x)))))
	(cond ((equal controlpow 1)
	       (setq result (add result (augmult (mul coef res1)))
		     count 2)
	       (go loop)))
	jump2 (setq res2 (add (augmult (mul* x expr expo
					     (inv (plus p p 2))))
			      (augmult (mul* b (plus p p 3)
					     (list '(rat) -1 4)
					     ex
					     (inv (plus p p p 1
							(times p p)
							(times p p)))
					     expr))
			      (augmult (mul (inv (plus p 1))
					    ex
					    (list '(rat) 1 8.)
					    (add (mul (power b 2)
						      (plus p p 3))
						 (mul -4 a c))
					    (numn pluspowfo1 c b a x)))))
	(cond ((equal controlpow 2)
	       (setq result (add result (augmult (mul coef res2)))
		     count 3)
	       (go loop)))
	jump3 (setq count 4 m 3)
	jump  (setq partres
		    ((lambda (pro)
		       (add (augmult (mul (power x (plus m -1))
					  expr expo pro))
			    (augmult (mul -1 b (plus p p m m -1)
					  1//2 expo pro res2))
			    (augmult (mul -1 a (plus m -1)
					  expo pro res1))))
		     (power (plus m p p) -1)))
	(setq m (plus  m 1))
	(cond ((greaterp m controlpow)
	       (setq result (add result (augmult (mul coef partres))))
	       (go loop)))
	jump4 (setq res1 res2 res2 partres)
	(go jump)
	loop  (setq poszpowlist (cdr poszpowlist))
	(cond ((null poszpowlist) (return result)))
	(setq coef (cadar poszpowlist))
	(setq controlpow (caar poszpowlist))
	(cond ((equal count 4) (go jump4)))
	(cond ((equal count 1) (go jump1)))
	(cond ((equal count 2) (go jump2)))
	(go jump3)))
   (power (polfoo c b a x) (add p 1//2)) *ec-1* (power c -2)))

(defun numn (p c b a x)
  (declare (special *ec-1*))
  ((lambda (exp1 exp2 exp3 exp4 exp5) 
     (cond ((zerop p) (add (augmult (mul (list '(rat) 1 4) exp1
					 exp2 (power (polfoo c b a x) exp3)))
			   (augmult (mul (list '(rat) 1 8) exp1 exp4 
					 (den1 c b a x)))))
	   (t (add (augmult (mul (list '(rat) 1 4) exp1 exp5 exp2
				 (power (polfoo c b a x) (add p exp3))))
		   (augmult (mul (list '(rat) 1 8) exp1 exp5 (plus p p 1)
				 exp4 (numn (plus p -1) c b a x)))))))
   *ec-1* (add b (mul 2 c x)) 1//2
   (add (mul 4 a c) (mul -1 b b)) (list '(rat) 1 (plus p 1))))

(defun augmult (x)
  ($multthru (simplifya x nil))) 
 
(defun denmdenn (negpowlist p c b a x)
  ((lambda (exp1)
     (prog (result controlpow coef count res1 res2 m partres signa ea-1)
	(setq signa (checksigntm (simplifya a nil)))
	(cond ((eq signa '$zero)
	       (return (noconstquad negpowlist p c b x))))
	(setq result 0 controlpow (caar negpowlist) ea-1 (power a -1))
	(setq coef (cadar negpowlist))
	(cond ((zerop controlpow)
	       (setq result (augmult  (mul coef (denn p c b a x)))
		     count 1)
	       (go loop)))
	jump1 (setq res1 (den1denn p c b a x))
	(cond ((equal controlpow 1)
	       (setq result (add result (augmult (mul coef res1)))
		     count 2)
	       (go loop)))
	jump2 (setq res2 (add (augmult (mul -1 ea-1 (power x -1) exp1))
			      (augmult (mul -1 b (plus 1 p p) 1//2
					    ea-1 (den1denn p c b a x)))
			      (augmult (mul -2 p c ea-1 (denn p c b a x)))))
	(cond ((equal controlpow 2)
	       (setq result (add result (augmult (mul coef res2)))
		     count 3)
	       (go loop)))
	jump3 (setq count 4 m 3)
	jump  (setq partres
		    ((lambda (exp2)
		       (add (augmult (mul exp2 ea-1
					  (power x (plus 1 (times -1 m)))
					  exp1))
			    (augmult (mul b (plus p p m m -3) 1//2
					  ea-1 exp2 res2))
			    (augmult (mul c ea-1 exp2
					  (plus p p m -2) res1))))
		     (simplifya (list '(rat) -1 (plus m -1)) nil)))
	(setq m (plus m 1))
	(cond ((greaterp m controlpow)
	       (setq result (add result (augmult (mul coef partres))))
	       (go loop)))
	jump4 (setq res1 res2 res2 partres)
	(go jump)
	loop  (setq negpowlist (cdr negpowlist))
	(cond ((null negpowlist) (return result)))
	(setq coef (cadar negpowlist)
	      controlpow (caar negpowlist))
	(cond ((equal count 4) (go jump4)))
	(cond ((equal count 1) (go jump1)))
	(cond ((equal count 2) (go jump2)))
	(go jump3)))
   (power (polfoo c b a x) (add 1//2 (times -1 p)))))

;; Integral of 1/(c*x^2+b*x+a)^(n), n > 0.  p = n - 1/2.
;;
;; See G&R 2.263 formula 3.
;;
;; Let R = c*x^2+b*x+a.
(defun denn (p c b a x)
  (declare (special *ec-1*))
  ((lambda (signdisc exp1 exp2 exp3 *ec-1*)
     ;; exp1 = b + 2*c*x;
     ;; exp2 = (4*a*c-b^2)
     ;; exp3 = 1/(2*p-1)
     #+nil
     (progn
       (format t "signdisc = ~A~%" signdisc)
       (format t "p = ~A~%" p))
     (cond ((and (eq signdisc '$zero)
		 (zerop p))
	    ;; 1/sqrt(R), and R has duplicate roots.  That is, we have
	    ;; 1/sqrt(c*(x+b/(2c))^2) = 1/sqrt(c)/sqrt((x+b/2/c)^2).
	    ;;
	    ;; We return 1/sqrt(c)*log(x+b/2/c).  Shouldn't we return
	    ;; 1/c*log(|x+b/2/c|)?
	    (augmult (mul* (power *ec-1* 1//2)
			   (list '(%log) (add x (mul b 1//2 *ec-1*))))))
	   ((and (eq signdisc '$zero)
		 (greaterp p 0))
	    ;; 1/sqrt(R^(2*p+1)), with duplicate roots.
	    ;;
	    ;; That is, 1/sqrt((c*(x+b/2/c)^(2)^(2*p+1))), or
	    ;; 1/c^(p+1/2)/(x+b/2/c)^(2*p+1).  So the result is 
	    ;;
	    ;; -1/2/p*c^(-p-1/2)/(x+b/2/c)^(2*p)
	    ;;
	    ;; FIXME:  This doesn't look right.
	    (augmult (mul* (list '(rat) -1 (plus p p))
			   (power c (mul (list '(rat) -1 2)
					 (plus p p 1)))
			   (power (add x (mul b 1//2  *ec-1*))
				  (times -2 p)))))
	   ((zerop p)
	    ;; 1/sqrt(R)
	    (den1 c b a x))
	   ((equal p 1)
	    ;; 1/sqrt(R^3).
	    ;;
	    ;; G&R 2.264 eq. 5 says
	    ;;
	    ;; 2*(2*c*x+b)/del/sqrt(R).
	    (augmult (mul 2 exp1 (inv exp2)
			  (power (polfoo c b a x)
				 (list '(rat) -1 2)))))
	   (t
	    ;; The general case.  G&R 2.263 eq. 3.
	    ;;
	    ;; integrate(1/sqrt(R^(2*p+1)),x) =
	    ;;    2*(2*c*x+b)/(2*p-1)/c/sqrt(R^(2*p-1))
	    ;;    + 8*(p-1)*c/(2*p-1)/del*integrate(1/sqrt(R^(2*p-1)),x)
	    ;;
	    ;; where del = 4*a*c-b^2.
	    (add (augmult (mul 2 exp1
			       exp3 (inv exp2)
			       (power (polfoo c b a x)
				      (add 1//2 (times -1 p)))))
		 (augmult (mul 8 c (plus p -1)
			       exp3 (inv exp2)
			       (denn (plus p -1) c b a x)))))))
   (signdis1 c b a)
   (add b (mul 2 c x))
   (add (mul 4 a c)
	(mul b b -1))
   (inv (plus p p -1))
   (inv c)))

;; Integral of 1/x/(c*x^2+b*x+a)^(p+1/2), p > 0.
(defun den1denn (p c b a x)
  ((lambda (signa ea-1)
     ;; signa = sign of a^2
     ;; ea-1 = 1/a.
     (cond ((eq signa '$zero)
	    ;; This is wrong because noconstquad expects a
	    ;; powercoeflist for th first arg.  But I don't think
	    ;; there's any way to get here from anywhere.  I'm pretty
	    ;; sure den1denn is never called with a equal to 0.
	    (noconstquad 1 p c b x))
	   ((zerop p)
	    ;; 1/x/sqrt(c*x^2+b*x+a)
	    (den1den1 c b a x))
	   (t
	    ;; The general case.  See G&R 2.268:
	    ;;
	    ;; R=(c*x^2+b*x+a)
	    ;;
	    ;; integrate(1/x/sqrt(R^(2*p+1)),x) =
	    ;;
	    ;;   1/(2*p-1)/a/sqrt(R^(2*p-1))
	    ;;     - b/2/a*integrate(1/sqrt(R^(2*p+1)),x)
	    ;;     + 1/a*integrate(1/x/sqrt(R^(2*p-1)),x)
	    (add (augmult (mul (inv (plus p p -1))
			       ea-1
			       (power (polfoo c b a x)
				      (add 1//2 (times -1 p)))))
		 (augmult (mul ea-1 (den1denn (plus p -1) c b a x)))
		 (augmult (mul -1 1//2 ea-1 b (denn p c b a x)))))))
   (checksigntm (power a 2))
   (power a -1)))

;; Integral of 1/x/sqrt(c*x^2+b*x+a).
;;
;; G&R 2.266 gives the following results, where del is the
;; discriminant 4*a*c-b^2.  (I think this is the opposite of what we
;; compute below for the discriminant.)
;;
(defun den1den1 (c b a x)
  ((lambda (exp2 exp3 exp4)
     ;; exp2 = b*x+2*a
     ;; exp3 = 1/abs(x)
     ;; exp4 = -1/2
     (prog (signdiscrim condition signa exp1)
	(setq signa (checksigntm (simplifya a nil)))
	(setq condition  (add (mul b x) a a))
	(cond ((eq signa '$zero)
	       (return (noconstquad '((1 1)) 0 c b x))))
	(setq signdiscrim (signdis3 c b a signa)
	      exp1 (power a (inv -2)))
	#+nil
	(progn
	  (format t "signa = ~A~%" signa)
	  (format t "signdiscrim = ~A~%" signdiscrim))
	(cond ((and (eq signa '$positive)
		    (eq signdiscrim '$negative))
	       ;; G&R case a > 0, del > 0
	       ;;
	       ;; -1/sqrt(a)*asinh((2*a+b*x)/x/sqrt(del)
	       (return (mul* -1 exp1
			     (list '(%asinh)
				   (augmult (mul exp2 exp3
						 (power (add (mul 4 a c)
							     (mul -1 b b))
							exp4))))))))
	(cond ((and (eq signdiscrim '$zero)
		    (eq signa '$positive))
	       ;; G&R case del = 0, a > 0
	       ;;
	       ;; 1/sqrt(a)*log(x/(2*a+b*x))
	       (return (mul* (power -1 condition)
			     -1 exp1
			     (list '(%log)
				   (augmult (mul exp3 exp2)))))))
	(cond ((eq signa '$positive)
	       ;; G&R case a > 0
	       ;;
	       ;; -1/sqrt(a)*log((2*a+b*x+2*sqrt(a*R))/x)
	       ;;
	       ;; R = c*x^2+b*x+a.
	       (return (mul* -1 exp1
			     (list '(%log)
				   (add b (mul 2 a exp3)
					(mul 2 exp3
					     (power a 1//2)
					     (power (polfoo c b a x)
						    1//2))))))))
	(cond ((and (eq signa '$negative)
		    (eq signdiscrim '$positive))
	       ;; G&R case a < 0, del < 0
	       ;;
	       ;; 1/sqrt(-a)*asin((2*a+b*x)/x/sqrt(b^2-4*a*c))
	       (return (mul* (power (mul -1 a) exp4)
			     (list '(%asin)
				   (augmult (mul exp2 exp3
						 (power (add (mul b b)
							     (mul -4 a c))
							exp4))))))))
	;; I think this is the case of a < 0.  We flip the sign of
	;; coefficients of the quadratic to make a positive, and
	;; multiply the result by 1/%i.
	;;
	;; Why can't we use the case a < 0 in G&R 2.266:
	;;
	;; 1/sqrt(-a)*atan((2*a+b*x)/2/sqrt(-a)/sqrt(R)
	;;
	;; FIXME:  Why the multiplication by -1?
	(return (mul #+nil -1
		     (power -1 1//2)
		     (den1den1 (mul -1 c) (mul -1 b) (mul -1 a) x)))))
   (add (mul b x) a a)
   (power (list '(mabs) x) -1)
   (list '(rat) -1 2)))

;; Integral of d/x^m/(c*x^2+b*x)^(p+1/2), p > 0.  The values of m and
;; d are in NEGPOWLIST.
(defun noconstquad (negpowlist p c b x)
  ((lambda (exp1 exp2 exp3)
     ;; exp1 = 1/(2*p+1)
     ;; exp2 = 1/x
     ;; exp3 = -p
     (prog (result controlpow coef count res1 signb m partres eb-1)
	(setq signb (checksigntm (power b 2)))
	(cond ((eq signb '$zero)
	       (return (trivial1 negpowlist p c x))))
	(setq result 0
	      controlpow (caar negpowlist)
	      coef (cadar negpowlist)
	      eb-1 (inv b))
	(cond ((zerop controlpow)
	       (setq result (augmult (mul coef (denn p c b 0 x)))
		     count 1)
	       (go loop)))
	jump1 (setq res1 (add (augmult (mul -2 exp1 eb-1 exp2
					    (power (polfoo c b 0 x)
						   (add 1//2 exp3))))
			      (augmult (mul -4 p c exp1 eb-1 (denn p c b 0 x)))))
	(cond ((equal controlpow 1)
	       (setq result (add result (augmult (mul coef res1)))
		     count 2)
	       (go loop)))
	jump2 (setq count 3 m 2)
	jump  (setq partres (add (augmult (mul -2 (inv (plus p p m m -1))
					       eb-1
					       (power x	(mul -1 m))
					       (power (polfoo c b 0 x)
						      (add 1//2 exp3))))
				 (augmult (mul -2 c (plus p p m -1)
					       eb-1 (inv (plus p p m m -1)) res1))))
	(setq m (plus m 1))
	(cond ((greaterp m controlpow)
	       (setq result (add result (augmult (mul coef partres))))
	       (go loop)))
	jump3 (setq res1 partres)
	(go jump)
	loop  (setq negpowlist (cdr negpowlist))
	(cond ((null negpowlist) (return result)))
	(setq coef (cadar negpowlist)
	      controlpow (caar negpowlist))
	(cond ((equal count 3) (go jump3)))
	(cond ((equal count 1) (go jump1)))
	(go jump2)))
   (inv (plus p p 1))
   (power x -1)
   (times -1 p)))

;; The trivial case of d/x^m/(c*x^2+b*x+a)^(p+1/2), p > 0, and a=b=0.
(defun trivial1 (negpowlist p c x)
  (cond ((null negpowlist) 0)
	(t (add (augmult (mul (power x
				     (add (times -2 p)
					  (mul -1
					       (caar negpowlist))))
			      (cadar negpowlist)
			      (power c
				     (add (times -1 p)
					  (list '(rat) -1 2)))
			      (inv (add (times -2 p)
					(mul -1 (caar negpowlist))))))
		(trivial1 (cdr negpowlist) p c x)))))

;; Integrate pl(x)/(c*x^2+b*x+a)^(p+1/2) where pl(x) is a polynomial
;; and p > 0.  The polynomial is given in POSZPOWLIST.
(defun nummdenn (poszpowlist p c b a x)
  (declare (special *ec-1*))
  ((lambda (exp1 exp2 exp3 exp4 exp5 exp6 exp7)
     ;; exp1 = 1/(2*p-1)
     ;; exp2 = (a*x^2+b*x+c)^(p-1/2)
     ;; exp3 = (4*a*c-b^2) (negative of the discriminant)
     ;; exp4 = b/2/c
     ;; exp5 = 1/c^2
     ;; exp6 = -2*p+2
     ;; exp7 = -2*p+1
     (prog (result controlpow coef count res1 res2 m partres signdiscrim)
	(setq result 0
	      controlpow (caar poszpowlist))
	(setq coef (cadar poszpowlist)
	      signdiscrim (signdis1 c b a))
	;; We're looking at coef*x^controlpow/R^(p+1/2) right now.
	(cond ((zerop controlpow)
	       ;; Actually it's coef/R^(p+1/2), so handle that now, go
	       ;; to the next coefficient.
	       (setq result (augmult (mul coef (denn p c b a x)))
		     count 1)
	       (go loop)))
	jump1
	;;
	;; This handles the case coef*x/R^(p+1/2)
	;;
	;; res1 = -1/c/(2*p-1)*R^(p-1/2)
	;;         -b/2/c*integrate(R^(p+1/2),x)
	;;
	;; Why do we compute this?
	(setq res1
	      (add (augmult (mul -1  *ec-1* exp1 exp2))
		   (augmult (mul b (list '(rat) -1 2)
				 *ec-1* (denn p c b a x)))))
	(cond ((equal controlpow 1)
	       ;; Integrate coef*x/R^(p+1/2).
	       (setq result (add result (augmult (mul coef res1)))
		     count 2)
	       (go loop)))
	jump2
	;; This handles the case coef*x^2/R^(p+1/2) 
	(cond ((and (greaterp p 0)
		    (not (eq signdiscrim '$zero)))
	       ;; p > 0, no repeated roots
	       (setq res2
		     (add (augmult (mul *ec-1* exp1 (inv exp3) exp2
					(add (mul 2 a b)
					     (mul 2 b b x)
					     (mul -4 a c x))))
			  (augmult (mul *ec-1* (inv exp3) exp1
					(add (mul 4 a c)
					     (mul 2 b b p)
					     (mul -3 b b))
					(denn (plus p -1)
					      c b a x)))))))
	(cond ((and (equal p 0)
		    (not (eq signdiscrim '$zero)))
	       ;; x^2/sqrt(R), no repeated roots.
	       (setq res2
		     (add (augmult (mul (list '(rat) 1 4)
					exp5
					(add (mul 2 c x)
					     (mul -3 b))
					(power (polfoo c b a x)
					       1//2)))
			  (augmult (mul (list '(rat) 1 8)
					exp5
					(add (mul 3 b b)
					     (mul -4 a c))
					(den1 c b a x)))))))
	(cond ((and (equal p 0)
		    (eq signdiscrim '$zero))
	       ;; x^2/sqrt(R), repeated roots
	       (setq res2
		     (add (augmult (mul* b b (list '(rat) 1 4)
					 (power c -3)
					 (list '(%log) exp4)))
			  (augmult (mul *ec-1* 1//2 (power exp4 2)))
			  (augmult (mul -1 b x exp5))))))
	
	(cond ((and (equal p 1)
		    (eq signdiscrim '$zero))
	       ;; x^2/sqrt(R^3), repeated roots
	       (setq res2
		     (add (augmult (mul* *ec-1* (list '(%log) exp4)))
			  (augmult (mul b exp5 (power exp4 -1)))
			  (augmult (mul (list '(rat) -1 8)
					(power c -3)
					b b (power exp4 -2)))))))
	
	(cond ((and (eq signdiscrim '$zero)
		    (greaterp p 1))
	       ;; x^2/R^(p+1/2), repeated roots, p > 1
	       (setq res2
		     (add (augmult (mul *ec-1* (power exp4 exp6)
					(inv exp6)))
			  (augmult (mul -1 b exp5 (inv exp7)
					(power exp4 exp7)))
			  (augmult (mul b b (list '(rat) -1 8)
					(power c -3)
					(inv p)
					(power exp4
					       (times -2 p))))))))
	(cond ((equal controlpow 2)
	       ;; x^2/R^(p+1/2)
	       (setq result (add result (augmult (mul coef res2)))
		     count 3)
	       (go loop)))
	jump3
	(setq count 4
	      m 3)
	jump
	;; coef*x^m/R^(p+1/2).  m >= 3
	(setq partres
	      ((lambda (denom pm-1)
		 ;; denom = 2*p-m
		 ;; pm-1 = m - 1

		 ;; x^(m-1)/c/denom*R^(-p+1/2)
		 ;;   - b*(2*p+1-2*m)/2/c/denom*res2
		 ;;   + a*(m-1)/c/denom*res1
		 (add (augmult (mul* (power x pm-1)
				     *ec-1* (list '(rat) -1 denom)
				     (power (polfoo c b a x)
					    (add 1//2
						 (times -1 p)))))
		      (augmult (mul b (plus p p 1 (times -2 m))
				    (list '(rat) -1 2)
				    *ec-1* (inv denom) res2))
		      (augmult (mul a pm-1 *ec-1* (inv denom) res1))))
	       (plus p p (times -1 m))
	       (plus m -1)))
	on
	;; Move on to next higher power
	(setq m (plus m 1))
	(cond ((greaterp m controlpow)
	       (setq result (add result (augmult (mul coef partres))))
	       (go loop)))
	jump4
	(setq res1 res2
	      res2 partres)
	(cond ((equal m (plus p p))
	       (setq partres
		     ((lambda (expr)
			(add (mul x expr)
			     (mul -1 (distrint (cdr ($expand expr))
					       x))))
		      (nummdenn (list (list (plus m -1) 1))
				p c b a x)))
	       (go on)))
	(go jump)
	loop
	;; Done with first term of polynomial.  Exit if we're done.
	(setq poszpowlist (cdr poszpowlist))
	(cond ((null poszpowlist) (return result)))
	(setq coef (cadar poszpowlist) controlpow (caar poszpowlist))
	(cond ((equal count 4) (go jump4)))
	(cond ((equal count 1) (go jump1)))
	(cond ((equal count 2) (go jump2)))
	(go jump3)))
   (inv (plus p p -1))
   (power (polfoo c b a x) (add 1//2 (times -1 p)))
   (add (mul 4 a c) (mul -1 b b))
   (add x (mul b 1//2 *ec-1*))
   (power c -2)
   (plus 2 (times -2 p))
   (plus 1 (times -2 p))))

(defun denmnumn (negpowlist pow c b a x)
  ((lambda (exp1 exp2)
     (prog (result controlpow p coef count res1 res2 m
	    partres signa ea-1)
	(setq p (plus pow pow -1))
	(cond ((eq (car negpowlist) 't)
	       (setq negpowlist (cdr negpowlist))
	       (go there)))
	(setq signa (checksigntm (power a 2)))
	(cond ((eq signa '$zero)
	       (return (nonconstquadenum negpowlist p c b x))))
	(setq ea-1 (inv a))
	there (setq result 0 controlpow (caar negpowlist)
		    coef (cadar negpowlist))
	(cond ((zerop controlpow)
	       (setq result (augmult (mul coef
					  (numn (add (mul p 1//2) 1//2)
						c b a x)))
		     count 1)
	       (go loop)))
	jump1 (setq res1 (den1numn pow c b a x))
	(cond ((equal controlpow 1)
	       (setq result (add result (augmult (mul coef res1)))
		     count 2)
	       (go loop)))
	jump2 (cond ((not (equal p 1))
		     (setq res2 (add (augmult (mul -1 exp1
						   (power (polfoo c b a x)
							  (add pow
							       (list '(rat) -1 2)))))
				     (augmult (mul b (list '(rat) exp2 2)
						   (den1numn (plus pow -1)
							     c b a x)))
				     (augmult (mul c exp2 (numn (plus pow -2)
								c b a x)))))))
	(cond ((equal p 1)
	       (setq res2 (add (augmult (mul -1 (power (polfoo c b a x)
						       1//2)
					     exp1))
			       (augmult (mul b 1//2 (den1den1 c b a x)))
			       (augmult (mul c (den1 c b a x)))))))
	(cond ((equal controlpow 2)
	       (setq result (add result (augmult (mul coef res2)))
		     count 3)
	       (go loop)))
	jump3 (setq count 4 m 3)
	jump  (setq partres
		    ((lambda (exp3 exp4)
		       (add (augmult (mul* (list '(rat) -1 exp3)
					   ea-1 (power x (plus 1 exp4))
					   (power (polfoo c b a x)
						  (add (list '(rat) p 2)
						       1))))
			    (augmult (mul (inv (plus m m -2))
					  ea-1 b (plus p 4 (times -2 m))
					  res2))
			    (augmult (mul c ea-1 (plus p 3 exp4)
					  (inv exp3) res1))))
		     (plus m -1) (times -1 m))
		    m (plus m 1))
	(cond ((greaterp m controlpow)
	       (setq result (add result (augmult (mul coef partres))))
	       (go loop)))
	jump4 (setq res1 res2 res2 partres)
	(go jump)
	loop  (setq negpowlist (cdr negpowlist))
	(cond ((null negpowlist) (return result)))
	(setq coef (cadar negpowlist) controlpow (caar negpowlist))
	(cond ((equal count 4) (go jump4)))
	(cond ((equal count 1) (go jump1)))
	(cond ((equal count 2) (go jump2)))
	(go jump3)))
   (power x -1) (plus pow pow -1)))

(defun nonconstquadenum (negpowlist p c b x)
  (prog (result coef m)
     (cond ((equal p 1)(return (case1 negpowlist c b x))))
     (setq result 0)
     loop (setq m (caar negpowlist) coef (cadar negpowlist))
     (setq result (add result (augmult (mul coef (casegen m p c b x))))
	   negpowlist (cdr negpowlist))
     (cond ((null negpowlist) (return result)))
     (go loop)))

(defun casegen (m p c b x)
  ((lambda (exp1 exp2 exp3 exp4 exp5)
     (cond ((equal p 1) (case1 (list (list m 1)) c b x))
	   ((zerop m) (case0 p c b x))
	   ((equal m (plus p 1))
	    (add (augmult (mul -1 exp1 (inv exp2) exp3))
		 (augmult (mul b 1//2 (casegen exp2 exp4 c b x)))
		 (augmult (mul c (casegen (plus m -2) exp4 c b x)))))
	   ((equal m 1) (add (augmult (mul (inv p) exp1))
			     (augmult (mul b 1//2 (case0 exp4 c b x)))))
	   (t (add (augmult (mul -1 exp1 (inv exp5) exp3))
		   (augmult (mul -1 p b 1//2 (inv exp5)
				 (casegen exp2 exp4 c b x)))))))
   (power (polfoo c b 0 x)(list '(rat) p 2))
   (plus m -1)
   (power x (plus 1 (times -1 m)))
   (plus p -2)
   (plus m -1 (times -1 p))))

(defun case1 (negpowlist c b x)
  (declare (special *ec-1*))
  ((lambda (exp1 eb-1)
     (prog (result controlpow m1 coef count res1 res2 m signc
	    signb partres res)
	(setq result 0 controlpow (caar negpowlist)
	      coef (cadar negpowlist) m1 (plus controlpow -2))
	(cond ((zerop controlpow)
	       (setq result (augmult (mul coef (case0 1 c b x)))
		     count 1)
	       (go loop)))
	jump1 (cond ((equal controlpow 1)
		     (setq result
			   (add result
				(augmult (mul coef (den1numn 1 c b 0 x))))
			   count 2)
		     (go loop)))
	jump2 (cond ((equal controlpow 2)
		     (setq result
			   (add result
				(augmult (mul coef
					      (denmnumn '(t (2 1))
							1 c b 0 x))))
			   count 3)
		     (go loop)))
	jump3 (setq signb (checksigntm (power b 2)))
	(cond ((eq signb '$zero)(setq count 5)(go jump5)))
	(setq count 4 m 0 signc (checksigntm *ec-1*))
	(cond ((eq signc '$positive)
	       (setq res
		     (augmult (mul* 2 exp1
				    (list '(%log)
					  (add (power (mul c x)
						      1//2)
					       (power (add b
							   (mul c x))
						      1//2))))))
	       (go jump4)))
	(setq res
	      (augmult (mul* 2 exp1
			     (list '(%atan)
				   (power (mul c x
					       (power (add b
							   (mul -1 c x))
						      -1))
					  1//2)))))
	jump4 (setq m (plus m 1)
		    res (add (augmult (mul -2 (power (polfoo c b 0 x) 1//2)
					   eb-1 (inv (pmm-1 m))
					   (ext-1m x m)))
			     (augmult (mul* (list '(rat) -2 (pmm-1 m))
					    c (sub1 m)
					    eb-1 res))))
	(cond ((equal m m1) (setq res2 res) (go jump4)))
	(cond ((equal (sub1 m) m1)
	       (if (null res2) (return nil))
	       (setq res1 res
		     partres (add (augmult (mul -1
						(power (polfoo c b 0 x)
						       1//2)
						(r1m m)
						(ext-1m x m)))
				  (augmult (mul b 1//2 (r1m m) res1))
				  (augmult (mul c (r1m m) res2))))
	       (go on)))
	(go jump4)
	jump5 (setq m controlpow)
	(cond ((zerop m)
	       (setq partres (mul* exp1 (list '(%log) x)))
	       (go on)))
	(setq partres (mul -1 exp1 (ext-1m x m) (r1m m)))
	on    (setq result (add result  (augmult (mul coef partres))))
	loop  (setq negpowlist (cdr negpowlist))
	(cond ((null negpowlist) (return result)))
	(setq coef (cadar negpowlist) controlpow (caar negpowlist))
	(cond ((equal count 5) (go jump5)))
	(cond ((equal count 1) (go jump1)))
	(cond ((equal count 2) (go jump2)))
	(cond ((equal count 3) (go jump3)))
	(setq m1 (plus controlpow -2))
	(cond ((equal m1 m) (setq res2 res1)))
	(go jump4)))
   (power c (list '(rat) -1 2)) (power b -1)))

(defun pmm-1 (m)
  (plus m m -1))

(defun r1m (m)
  (list '(rat) 1 m))

(defun ext-1m (x m)
  (power x (times -1 m))) 

(defun case0 (power c b x)
  ((lambda (exp1 exp2 exp3 exp4 eb-1)
     (declare (special *ec-1*))
     (prog (signc p result)
	(setq signc (checksigntm *ec-1*) p 1)
	(cond ((eq signc '$positive)
	       (setq result
		     (add (augmult (mul exp1 *ec-1* exp2
					(power (polfoo c b 0 x)
					       1//2)))
			  (augmult (mul* b b (list '(rat) -1 8)
					 exp3
					 (list '(%log)
					       (add exp2
						    (mul 2
							 (power c 1//2)
							 (power
							  (polfoo c b 0 x)
							  1//2))))))))))
	(cond ((eq signc '$negative)
	       (setq result
		     (add (augmult (mul exp1 *ec-1* exp4
					(power (polfoo (mul -1 c)
						       b 0 x)
					       1//2)))
			  (augmult (mul* b b (list '(rat) 1 8)
					 exp3
					 (list '(%asin)
					       (mul eb-1 exp4))))))))
	loop  (cond ((equal power p) (return result)))
	(setq p (plus p 2)
	      result ((lambda (exp5)
			(add (augmult (mul 1//2 *ec-1* exp5 exp2
					   (power (polfoo c b 0 x)
						  (list '(rat) p 2))))
			     (augmult (mul p b b (list '(rat) -1 4)
					   *ec-1* exp5 result))))
		      (inv (plus p 1))))
	(go loop)))
   (list '(rat) 1 4) (add b (mul 2 c x)) (power c (list '(rat) -3 2))
   (add (mul 2 c x)(mul -1 b)) (power b -1)))

(defun den1numn (p c b a x)
  (cond ((equal p 1)
	 (add (power (polfoo c b a x) 1//2 )
	      (augmult (mul a (den1den1 c b a x)))
	      (augmult (mul b 1//2 (den1 c b a x)))))
	(t (add (augmult (mul (power (polfoo c b a x)
				     (add p (list '(rat) -1 2)))
			      (inv (plus p p -1))))
		(augmult (mul a (den1numn (plus p -1) c b a x)))
		(augmult (mul b 1//2 (numn (plus p -2) c b a x)))))))

(defun distrint (expr x)
  (cond ((null expr) 0)
	(t (add (intira (car expr) x)
		(distrint (cdr expr) x)))))

