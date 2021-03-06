(in-package :cl-cad)

(defvar *signal* nil)
(defvar *end* 0)

(defun draw-shadow ()
  (cond
    ((equal *signal* :line) (input-for-line))
    ((equal *signal* :circle) (input-for-circle))
    ((equal *signal* :circle-diameter) (input-for-circle-diameter))
    ((equal *signal* :arc) (input-for-arc))
    ((equal *signal* :continious) (input-for-continious))
    ((equal *signal* :ray) (input-for-ray))
    ((equal *signal* :point) (input-for-point))
    ((equal *signal* :rectangle) (input-for-rectangle))
    ((equal *signal* :text) (input-for-text))
    ((equal *signal* :raster-image) (input-for-raster-image))
    ))

(defun get-coord-angle ()
  (cond
   ((> *current-x* *x*)
    (cond
     ((> *current-y* *y*)
      (* (atan (/ (- *current-y* *y*)
		  (- *current-x* *x*)))
	 (/ 180 pi)))
     ((< *current-y* *y*)
      (* (atan (/ (- *current-y* *y*)
		  (- *current-x* *x*)))
	 (/ 180 pi)))
     ((= *current-y* *y*)
      0)))
   ((< *current-x* *x*)
    (cond
     ((> *current-y* *y*)
      (- (* (atan (/ (- *current-y* *y*)
		     (- *current-x* *x*)))
	       (/ 180 pi)) 
	 180))
     ((< *current-y* *y*)
      (+ (* (atan (/ (- *current-y* *y*)
		     (- *current-x* *x*)))
	    (/ 180 pi))
	 180))
     ((= *current-y* *y*)
      180)))
   ((= *current-x* *x*)
    (cond
     ((> *current-y* *y*)
      90)
     ((< *current-y* *y*)
      270)
     ((= *current-y* *y*)
      0)))))

(defun get-coord-length ()
  (sqrt
   (+
    (* (- *x* *current-x*)
       (- *x* *current-x*))
    (* (- *y* *current-y*)
       (- *y* *current-y*)))))

(defun set-fantom-color ()
  (set-source-rgb (color-gtk-to-cairo (color-red (config-dim-color *config*)))
		  (color-gtk-to-cairo (color-green (config-dim-color *config*)))
		  (color-gtk-to-cairo (color-blue (config-dim-color *config*)))))

(defun input-for-line ()
  (set-source-rgb 1 0 0)
  (set-line-width 0.5)
  (move-to 
   (if (equal *x* 0) 
       *current-x*
       *x*)
   (if (equal *y* 0) 
       *current-y*
       *y*))
  (line-to *current-x* *current-y*)
  (stroke)
  (get-snap-coordinates)
  (if (equal *end* 2)
   (progn 
     (add-line *current-layer* 
	       (if (equal *snap-x1* 0)
		   (/ *x* *scroll-units*)
		   *snap-x1*)
	       (if (equal *snap-y1* 0)
		   (/ *y* *scroll-units*)
		   *snap-y1*)
	       0 
	       (if (equal *snap-x2* 0)
		   (/ *current-x* *scroll-units*)
		   *snap-x2*)
	       (if (equal *snap-y2* 0)
		   (/ *current-y* *scroll-units*) 
		   *snap-y2*)
	       0 
	       *line-type* 
	       1 
	       *current-color* 
	       *current-width*)
     (setf *end* 0 *snap-distance* 500 *snap-x1* 0 *snap-y1* 0 *snap-x2* 0 *snap-y2* 0 *x* 0 *y* 0))))

(defun input-for-circle ()
  (set-source-rgb 1 0 0)
  (set-line-width 0.5)
  (arc (if (equal *x* 0) 
	   *current-x*
	   *x*)
       (if (equal *y* 0) 
	   *current-y*
	   *y*)
       (if (equal *end* 0)
	   0
	   (get-coord-length))
       0 (* 2 pi))
  (stroke)
  (set-source-rgb 1 0 0)
  (move-to (+ *x* 5) *y*)
  (line-to (- *x* 5) *y*)
  (move-to *x* (+ *y* 5))
  (line-to *x* (- *y* 5))
  (stroke)
  (set-fantom-color)
  (move-to (if (equal *x* 0) 
	       *current-x*
	       *x*)
	   (if (equal *y* 0) 
	       *current-y*
	       *y*))
  (line-to *current-x* *current-y*)
  (stroke)
  (if (equal *end* 2)
      (progn
	(add-circle 
	 *current-layer*
	 (/ *x* *scroll-units*) 
	 (/ *y* *scroll-units*) 
	 0
	 (/ (get-coord-length) *scroll-units*) 
	 *line-type* 
	 1  
	 *current-color* 
	 *current-width*)
	(setf *x* 0 *y* 0)
	(setf *end* 0))))

(defun input-for-circle-diameter ()
  (set-source-rgb 1 0 0)
  (set-line-width 0.5)
  (arc (if (equal *x* 0) 
	   *current-x*
	   (* 0.5 (+ *current-x* *x*)))
       (if (equal *y* 0) 
	   *current-y*
	   (* 0.5 (+ *current-y* *y*)))
       (if (equal *end* 0)
	   0
	   (* 0.5 (get-coord-length)))
       0 (* 2 pi))
  (stroke)
  (set-source-rgb 1 0 0)
  (move-to (+ *x* 5) *y*)
  (line-to (- *x* 5) *y*)
  (move-to *x* (+ *y* 5))
  (line-to *x* (- *y* 5))
  (stroke)
  (set-fantom-color)
  (move-to (if (equal *x* 0) 
	       *current-x*
	       *x*)
	   (if (equal *y* 0) 
	       *current-y*
	       *y*))
  (line-to *current-x* *current-y*)
  (stroke)
  (if (equal *end* 2)
      (progn
	(add-circle 
	 *current-layer*
	 (/ (* 0.5 (+ *current-x* *x*)) *scroll-units*) 
	 (/ (* 0.5 (+ *current-y* *y*)) *scroll-units*) 
	 0 
	 (/ (* 0.5 (get-coord-length)) *scroll-units*) 
	 *line-type* 
	 1  
	 *current-color* 
	 *current-width*)
	(setf *x* 0 *y* 0)
	(setf *end* 0))))

(defun input-for-arc ()
  (set-source-rgb 1 0 0)
  (set-line-width 0.5)
  (if (equal *end* 1)
      (setf *angle1* (get-coord-angle)))
  (if (equal *end* 2)
      (setf *angle2* (get-coord-angle)))
  (if (equal *end* 1)
      (setf *length* (get-coord-length)))
  (arc (if (equal *x* 0) 
	   *current-x*
	   *x*)
       (if (equal *y* 0) 
	   *current-y*
	   *y*)
       (if (equal *end* 0)
	   1
	   *length*)
       (if (equal *end* 1)
	   0
	   (deg-to-rad *angle1*))
       (if (equal *end* 2)
	   (deg-to-rad *angle2*)
	   (* 2 pi)))
  (stroke)
  ;shadow
  (set-source-rgb 1 0 0)
  (move-to (+ *x* 5) *y*)
  (line-to (- *x* 5) *y*)
  (move-to *x* (+ *y* 5))
  (line-to *x* (- *y* 5))
  (stroke)
  (set-fantom-color)
  (move-to (if (equal *x* 0) 
	       *current-x*
	       *x*)
	   (if (equal *y* 0) 
	       *current-y*
	       *y*))
  (line-to *current-x* *current-y*)
  (stroke)
  ;write
  (if (equal *end* 3)
      (progn
	(add-arc 
	 *current-layer* 
	 (/ *x* *scroll-units*) 
	 (/ *y* *scroll-units*) 
	 0
	 (/ *length* *scroll-units*)
	 *angle1* 
	 *angle2* 
	 *line-type* 
	 1  
	 *current-color* 
	 *current-width*)
	(setf *x* 0 *y* 0)
	(setf *end* 0)
	(setf *angle1* 0 *angle2* 0 *length* 0))))

(defun input-for-continious ()
  (set-source-rgb 1 0 0)
  (set-line-width 0.5)
  (move-to 
   (if (equal *x* 0) 
       *current-x*
       *x*)
   (if (equal *y* 0) 
       *current-y*
       *y*))
  (line-to *current-x* *current-y*)
  (stroke)
  (if (equal *end* 2)
      (progn 
       (add-continious 
	*current-layer* 
	(/ *x* *scroll-units*) 
	(/ *y* *scroll-units*) 
	0 
	(/ *current-x* *scroll-units*) 
	(/ *current-y* *scroll-units*) 
	0)
       (setf *x* 0 *y* 0 *end* 0))))

(defun input-for-ray ()
  (set-source-rgb 1 0 0)
  (set-line-width 0.5)
  (move-to 
   (if (equal *x* 0) 
       *current-x*
       *x*)
   (if (equal *y* 0) 
       *current-y*
       *y*))
  (line-to
   (if (equal *x* 0) 
       *current-x*
       (cond
	 ((> *x* *current-x*)
	  0)
	 ((< *x* *current-x*)
	  (max *draw-width* *draw-height*))
	 ((= *x* *current-x*)
	  *x*)))
   (if (equal *y* 0) 
       *current-y*
       (cond
	 ((> *x* *current-x*)
	  (* -1 
	     (/ (- (* *x* *current-y*) (* *current-x* *y*)) 
		(- *current-x* *x*))))
	 ((< *x* *current-x*)
	  (* -1
	     (/ (+ (* (max *draw-width* *draw-height*) (- *y* *current-y*))
		   (- (* *x* *current-y*) (* *current-x* *y*))) 
		(- *current-x* *x*))))
	 ((= *x* *current-x*)
	  (if (> *y* *current-y*)
	      0
	      *draw-height*)))))
  (stroke)
  (if (equal *end* 2)
      (progn 
       (add-ray 
	*current-layer* 
	(/ *x* *scroll-units*) 
	(/ *y* *scroll-units*) 
	0 
	(/ *current-x* *scroll-units*)
	(/ *current-y* *scroll-units*)
	0)
       (setf *x* 0 *y* 0)
       (setf *end* 0))))

(defun input-for-point ()
  (set-source-rgb 1 0 0)
  (set-line-width 0.5)
  (rectangle (- (/ *scroll-units* *current-x*) 0.5)
	     (- (/ *scroll-units* *current-y*) 0.5)
	     1 1)
  (fill-path)
  (restore)
  (if (equal *end* 1)
      (progn 
       (add-point 
	*current-layer* 
	(/ *x* *scroll-units*) 
	(/ *y* *scroll-units*) 
	0 
	1)
       (setf *x* 0 *y* 0)
       (setf *end* 0))))

(defun input-for-rectangle ()
  (set-source-rgb 1 0 0)
  (set-line-width 0.5)
  (rectangle (if (equal *x* 0) 
		 *current-x*
		 *x*)
	     (if (equal *y* 0) 
		 *current-y*
		 *y*)
	     (if (equal *x* 0)
		 0
		 (- *current-x* *x*))
	     (if (equal *y* 0)
		 0
		 (- *current-y* *y*)))
  (stroke)
  (restore)
  (if (equal *end* 2)
      (progn 
       (add-rectangle 
	*current-layer* 
	(/ *x* *scroll-units*) 
	(/ *y* *scroll-units*) 
	0 
	(/ *current-x* *scroll-units*) 
	(/ *current-y* *scroll-units*) 
	0 
	*line-type*
	1 
	*current-color* 
	*current-width*)
       (setf *x* 0 *y* 0)
       (setf *end* 0))))

(defun input-for-text ()
  (set-source-rgb 1 0 0)
  (move-to (if (equal *x* 0) 
	       *current-x*
	       *x*)
	   (if (equal *y* 0) 
	       *current-y*
	       *y*))
  (show-text *text-buffer-count*)
  (stroke)
  (if (equal *end* 1)
      (if (equal *text-buffer-count* "")
	  (setf *end* 0)
	  (progn 
	    (add-text 
	     *current-layer* 
	     (/ *x* *scroll-units*) 
	     (/ *y* *scroll-units*)
	     0 
	     *text-buffer-count* 
	     *current-font*
	     0
	     *current-color*)
	    (setf *text-buffer-count* "" *x* 0 *y* 0 *end* 0)))))

(defun input-for-raster-image ()
  (set-source-rgb 1 0 0)
  (translate  (if (equal *x* 0) 
		  *current-x*
		  *x*)
	      (if (equal *y* 0) 
		  *current-y*
		  *y*)))
  
  