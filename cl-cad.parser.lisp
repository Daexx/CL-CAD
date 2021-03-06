(in-package :cl-cad)

(defun dash-gen (cd)
  (cond
    ((equal (getf cd :line-type) :continious) nil)
    ((equal (getf cd :line-type) :dashed) (set-dash 0 '(8 6)))
    ((equal (getf cd :line-type) :dashed-small) (set-dash 0 '(4 2)))
    ((equal (getf cd :line-type) :dashed-big) (set-dash 0 '(12 10)))
    ((equal (getf cd :line-type) :dot) (set-dash 0 '(1 6)))
    ((equal (getf cd :line-type) :dot-small) (set-dash 0 '(1 2)))
    ((equal (getf cd :line-type) :dot-big) (set-dash 0 '(1 10)))
    ))
    

(defun color-parser (cd)
  (set-source-rgb (color-gtk-to-cairo (color-red (getf cd :color-line)))
		  (color-gtk-to-cairo (color-green (getf cd :color-line)))
		  (color-gtk-to-cairo (color-blue (getf cd :color-line)))))

(defun parser-line (cd)
  (save)
  (color-parser cd)
  (set-line-width (getf cd :width))
  (dash-gen cd)
  (move-to (+ *screen-units-x* (* *scroll-units* (getf cd :x1)))
	   (+ *screen-units-y* (* *scroll-units* (getf cd :y1))))
  (line-to (+ *screen-units-x* (* *scroll-units* (getf cd :x2)))
	   (+ *screen-units-y* (* *scroll-units* (getf cd :y2))))
  (stroke)
  (restore))

(defun parser-circle (cd)
  (save)
  (color-parser cd)
  (set-line-width (getf cd :width))
  (dash-gen cd)
  (arc (+ *screen-units-x* (* *scroll-units* (getf cd :x1)))
       (+ *screen-units-y* (* *scroll-units* (getf cd :y1)))
       (* *scroll-units* (getf cd :radius))
       0 (* 2 pi))
  (stroke)
  (restore))
  
(defun parser-arc (cd)
  (save)
  (color-parser cd)
  (set-line-width (getf cd :width))
  (dash-gen cd)
  (arc (+ *screen-units-x* (* *scroll-units* (getf cd :x1)))
       (+ *screen-units-y* (* *scroll-units* (getf cd :y1)))
       (* *scroll-units* (getf cd :radius)) 
       (deg-to-rad (getf cd :startangle)) 
       (deg-to-rad (getf cd :endangle)))
  (stroke)
  (restore))

(defvar *temp-x* nil)

(defun parser-continious (cd w h)
  (set-source-rgb 0 0 1)
  (set-line-width 1)
  (move-to (* *scroll-units* (getf cd :x1))
	   (* *scroll-units* (getf cd :y1)))
  (line-to (* *scroll-units* (getf cd :x2))
	   (* *scroll-units* (getf cd :y2)))
 ; (move-to (* *scroll-units* (let ((x1 (getf cd :x1))
;				   (y1 (getf cd :y1))
;				   (x2 (getf cd :x2))
;				   (y2 (getf cd :y2)))
;			       (setf *temp-x* (+ 
;					(* (- 0 y1) 
;					   (/ (- x2 x1) 
;					      (- y2 y1)))
;					x1))
;			       *temp-x*))
;	   (* *scroll-units* (let ((x1 (getf cd :x1))
;				   (y1 (getf cd :y1))
;				   (x2 (getf cd :x2))
;				   (y2 (getf cd :y2)))
;			       (* (/ (- y2 y1)
;				     (- x2 x1))
;				  (- *temp-x* x1)))))
;  (line-to (* (/ (getf cd :x1) *scroll-units*) 
;	      (let ((x1 (getf cd :x1))
;		    (y1 (getf cd :y1))
;		    (x2 (getf cd :x2))
;		    (y2 (getf cd :y2)))
;		(+ 
;		 (* (- w y1) 
;		    (/ (- x2 x1) 
;		       (- y2 y1)))
;		 x1)))
;	   (* (/ (getf cd :y1) *scroll-units*) 
;	      (let ((x1 (getf cd :x1))
;		    (y1 (getf cd :y1))
;		    (x2 (getf cd :x2))
;		    (y2 (getf cd :y2)))
;		(* (/ (- y2 y1)
;		      (- x2 x1))
;		   (- h x1)))))
  (stroke))

(defun parser-ray (cd w h)
  (set-source-rgb 0 0 1)
  (set-line-width 1)
  (let ((x1 (getf cd :x1))
	(y1 (getf cd :y1))
	(x2 (getf cd :x2))
	(y2 (getf cd :y2)))
    (move-to (+ *screen-units-x* (* *scroll-units* x1))
	     (+ *screen-units-y* (* *scroll-units* y1)))
    (line-to (+ *screen-units-x*
		(* *scroll-units*
		   (cond
		     ((> x1 x2)
		      0)
		     ((< x1 x2)
		      (max *draw-width* *draw-height*))
		     ((= x1 x2)
		      x1))))
	     (+ *screen-units-y*
		(* *scroll-units*
		   (cond
		     ((> x1 x2)
		      (* -1 
			 (/ (- (* x1 y2) (* x2 y1)) 
			    (- x2 x1))))
		     ((< x1 x2)
		      (* -1
			 (/ (+ (* (max *draw-width* *draw-height*) (- y1 y2))
			       (- (* x1 y2) (* x2 y1))) 
			    (- x2 x1))))
		     ((= x1 x2)
		      (if (> y1 y2)
			  0
			  *draw-height*)))))))
  (stroke))

(defun split-by-one-space (string)
  (loop for i = 0 then (1+ j)
     as j = (position #\Space string :start i)
     collect (subseq string i j)
     while j))

(defun gtkfont-to-cairofont (cd)
  (cond ((= (length (split-by-one-space (getf cd :style))) 4)
	 (select-font-face
	  (car (split-by-one-space (getf cd :style)))
	  (or
	   (cond 
	     ((equal (caddr (split-by-one-space (getf cd :style))) "Italic") :italic))
	   :normal)
	  (or
	   (cond
	     ((equal (cadr (split-by-one-space (getf cd :style))) "Bold") :bold))
	   :normal)))

	((= (length (split-by-one-space (getf cd :style))) 3)
	 (if (equal (cadr (split-by-one-space (getf cd :style))) "Bold")
	     (select-font-face
	      (car (split-by-one-space (getf cd :style)))
	      :normal
	      :bold)
	     (select-font-face
	      (car (split-by-one-space (getf cd :style)))
	      :italic
	      :normal)))
	      
	((= (length (split-by-one-space (getf cd :style))) 2)
	 (select-font-face
	  (car (split-by-one-space (getf cd :style)))
	  :normal
	  :normal))))
	      
	      
	      
   

(defun parser-text (cd)
  (save)
  (color-parser cd)
  (move-to (+ *screen-units-x* (* *scroll-units* (getf cd :x1)))
	   (+ *screen-units-y* (* *scroll-units* (getf cd :y1))))
  (gtkfont-to-cairofont cd)
  (set-font-size (* *scroll-units*
		    (parse-integer 
		     (car
		      (reverse 
		       (split-by-one-space (getf cd :style)))))))
  (show-text (getf cd :count))
  (stroke)
  (restore))

;(defun parser-block ()

(defun parser-point (cd)
  (save)
  (set-source-rgb 1 0 1)
  (rectangle (+ *screen-units-x* (- (* *scroll-units* (getf cd :x1)) 0.5))
	     (+ *screen-units-y* (- (* *scroll-units* (getf cd :y1)) 0.5))
	     1 1)
  (fill-path)
  (restore))

(defun parser-ellipse (cd w h)
  (save)
 ; (scale 2 1)
 ; (rotate (deg-to-rad (getf cd :angle)))
  (dash-gen cd)
  (color-parser cd)
  (set-line-width (getf cd :width))
  (arc (* *scroll-units* (getf cd :x1))
       (* *scroll-units* (getf cd :y1))
       (* *scroll-units* (getf cd :major-radius))
       0 (* 2 pi))
  (stroke)
  (restore))
  
(defun parser-raster-image (cd)
  (let* ((image (image-surface-create-from-png (getf cd :path)))
	 (image-width (image-surface-get-width image))
	 (image-height (image-surface-get-height image)))
    (translate (* *scroll-units* (getf cd :x1)) 
	       (* *scroll-units* (getf cd :y1)))
    (rotate (* (getf cd :rotation-angle) (* pi 180)))
    (scale (* *scroll-units* (/ (getf cd :scale) image-width)) 
	   (* *scroll-units* (/ (getf cd :scale) image-height)))
    (translate (* -0.5 image-width) (* -0.5 image-height))
    (set-source-surface image 0 0)
    (paint)))

;(defun parser-raster-image (cd)
;  (save)
;  (let* ((image (image-surface-create-from-png (getf cd :path)));
;	 (image-width (image-surface-get-width image))
;	 (image-height (image-surface-get-height image)))
;    (translate (* *scroll-units* (getf cd :x1)) ;
;	       (* *scroll-units* (getf cd :y1)))
 ;   (rotate (* (getf cd :rotation-angle) (* pi 180)))
  ;  (scale (* *scroll-units* (/ (getf cd :scale) image-width)) (* *scroll-units* (/ (getf cd :scale) image-height)))
   ; (translate (* -0.5 image-width) (* -0.5 image-height))
   ; (set-source-surface image 0 0)
   ; (paint)
   ; (restore)))

(defun parser-rectangle (cd)
  (save)
  (dash-gen cd)
  (color-parser cd)
  (set-line-width (getf cd :width))
  (rectangle (+ *screen-units-x* (* *scroll-units* (getf cd :x1)))
	     (+ *screen-units-x* (* *scroll-units* (getf cd :y1)))
	     (* *scroll-units* (- (getf cd :x2) (getf cd :x1)))
	     (* *scroll-units* (- (getf cd :y2) (getf cd :y1))))
  (stroke)
  (restore))
  
(defun parser (w h)
  (dolist (cd *current-draw*)
	     (cond
	       ((equal (getf cd :title) :line) (parser-line cd))
	       ((equal (getf cd :title) :circle) (parser-circle cd))
	       ((equal (getf cd :title) :arc) (parser-arc cd))
	       ((equal (getf cd :title) :continious) (parser-continious cd w h))
	       ((equal (getf cd :title) :ray) (parser-ray cd w h))
	       ((equal (getf cd :title) :text) (parser-text cd))
	       ((equal (getf cd :title) :point) (parser-point cd))
	       ((equal (getf cd :title) :ellipse) (parser-ellipse cd w h))
	       ((equal (getf cd :title) :raster-image) (parser-raster-image cd))
	       ((equal (getf cd :title) :rectangle) (parser-rectangle cd))
	       )))
