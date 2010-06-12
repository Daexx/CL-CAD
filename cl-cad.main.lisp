(in-package :cl-cad)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defclass cairo-w (drawing-area)
    ((draw-fn :initform 'draw-space1 :accessor cairo-w-draw-fn))
    (:metaclass gobject:gobject-class)))

(defmethod initialize-instance :after ((w cairo-w) &rest initargs)
  (declare (ignore initargs))
  (gobject:connect-signal w "configure-event" (lambda (widget event)
                                                (declare (ignore event))
                                                (widget-queue-draw widget)))
  (gobject:connect-signal w "expose-event" (lambda (widget event)
                                             (declare (ignore event))
                                             (cc-expose widget)))
  (gobject:connect-signal w "motion-notify-event" (lambda (widget event)
                                                       (declare (ignore event))
                                                       (setf x (event-motion-x event)
                                                             y (event-motion-y event))
                                                       (widget-queue-draw widget))))

(defmethod (setf cairo-w-draw-fn) :after (new-value (w cairo-w))
  (declare (ignore new-value))
  (widget-queue-draw w))

(defun cc-expose (widget)
  (multiple-value-bind (w h) (gdk:drawable-get-size (widget-window widget))
    (with-gdk-context (ctx (widget-window widget))
      (with-context (ctx)
	(funcall (cairo-w-draw-fn widget) w h)
        nil))))

;	(set-source-rgb 0 0 0)
;	(paint)
 ;       (move-to 200 10)
;	(line-to 100 10)
;	(line-to 100 400)
;	(line-to 700 400)
;	(line-to 700 10)
;	(line-to 300 10)
;	(set-source-rgb 0.2 0.2 1)
;	(set-line-width 4)
;	(stroke)
;	(rectangle 110 50 105 345)
;	(set-source-rgb 1 1 1)
;	(fill-path)
;	(rectangle 420 15 150 50)
;	(set-source-rgb 1 1 1)
;	(fill-path)
;	(rectangle 320 15 80 80)
;	(set-source-rgb 1 1 1)
;	(fill-path)
;	(rectangle 500 300 195 95)
;	(set-source-rgb 1 1 0.5)
;	(fill-path)
;	(rectangle 600 100 95 295)
;	(set-source-rgb 1 1 0.5)
;	(fill-path)


(defun menu-window ()
  (within-main-loop
   (let ((w (make-instance 'gtk-window :type :popup :destroy-with-parent t :window-position :mouse))
	  (v-box (make-instance 'v-box))
	  (menuitem-file (make-instance 'menu-item :label "File"))
	 (menuitem-edit (make-instance 'menu-item :label "Edit"))
	 (menuitem-view (make-instance 'menu-item :label "View"))
	 (menuitem-about (make-instance 'menu-item :label "About"))
	  (button (make-instance 'button :label "exit")))
     (container-add w v-box)
     (container-add v-box menuitem-file)
     (container-add v-box menuitem-edit)
     (container-add v-box menuitem-view)
     (container-add v-box menuitem-about)
     (container-add v-box button)
     (gobject:g-signal-connect w "destroy" (lambda (b) (declare (ignore b)) (leave-gtk-main)))
     (widget-show w))))

(defun main-window ()
  (within-main-loop
   (let* ((w (make-instance 'gtk-window :title "CL-CAD" :type :toplevel :window-position :center :default-width 1024 :default-height 600))
	 (v-box (make-instance 'v-box))
	 (h-box (make-instance 'h-box))
	 (menu-notebook (make-instance 'notebook :enable-popup t))
	 (draw-area (make-instance 'cairo-w))
	 (vpaned (make-instance 'v-paned))
	 (toolbar (make-instance 'toolbar :show-arrow t :toolbar-style :icons :tooltips t))
	 (icon (make-instance 'status-icon :file (namestring (merge-pathnames "graphics/icon.svg" *src-location*))))
	 ;terminal
	 (term-notebook (make-instance 'notebook :enable-popup t :tab-pos :left))
	 (term-vbox (make-instance 'v-box))
	 (term-hbox (make-instance 'h-box))
	 (tools-vbox (make-instance 'v-box))
	 (term-buffer (make-instance 'text-buffer))
	 (term-text-view (make-instance 'text-view :buffer term-buffer))
	 (term-new (make-instance 'button :image (make-instance 'image :stock "gtk-new")))
	 (term-open (make-instance 'button :image (make-instance 'image :stock "gtk-open")))
	 (term-save (make-instance 'button :image (make-instance 'image :stock "gtk-save")))
	 (term-save-as (make-instance 'button :image (make-instance 'image :stock "gtk-save-as")))
	 (term-eval (make-instance 'button :image (make-instance 'image :stock "gtk-execute")))
	 (term-scrolled (make-instance 'scrolled-window :hscrollbar-policy :automatic :vscrollbar-policy :automatic))
         ;;;system
	 (button-save (make-instance 'button :image (make-instance 'image :stock "gtk-save")))
	 (button-save-as (make-instance 'button :image (make-instance 'image :stock "gtk-save-as")))
	 (button-new (make-instance 'button :image (make-instance 'image :stock "gtk-new")))
	 (button-open (make-instance 'button :image (make-instance 'image :stock "gtk-open")))
	 (button-print (make-instance 'button :image (make-instance 'image :stock "gtk-print")))
	 (button-print-prop (make-instance 'button :image (make-instance 'image :stock "gtk-page-setup")))
	 (button-system-properties (make-instance 'button :image (make-instance 'image :stock "gtk-properties")))
	 (button-layers (make-instance 'button :image (make-instance 'image :stock "gtk-justify-fill")))
	 (button-file-prop (make-instance 'button :image (make-instance 'image :stock "gtk-preferences")))
	 (button-color-selection (make-instance 'color-button :has-opacity-control t))
	 (button-select-font (make-instance 'font-button :font-name "Sans 10"))
	 (button-full (make-instance 'toggle-button :image (make-instance 'image :stock "gtk-fullscreen")))
	 (button-osnap (make-instance 'button :label "Osnap"))
         ;;;primitives
	 (primitives-expander (make-instance 'expander :expanded t :label "Primitives"))
	 (primitives-table (make-instance 'table :n-rows 5 :n-columns 4 :homogeneous nil))
	 (button-line (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/line.svg" *src-location*)))))
	 (button-ray (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/ray.svg" *src-location*)))))
	 (button-construction (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/construction.svg" *src-location*)))))
	 (button-circle-radius (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circleradius.svg" *src-location*)))))
	 (button-circle-2p (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circle2p.svg" *src-location*)))))
	 (button-circle-3p (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circle3p.svg" *src-location*)))))
	 (button-circle-diameter (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circlediameter.svg" *src-location*)))))
	 (button-circle-ttr (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circlettr.svg" *src-location*)))))
	 (button-circle-ttt (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/circlettt.svg" *src-location*)))))
	 (button-arc (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/arc3p.svg" *src-location*)))))
	 (button-ellipse-center (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/ellipsecenter.svg" *src-location*)))))
	 (button-ellipse-axis (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/ellipseaxis.svg" *src-location*)))))
	 (button-ellipse-arc (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/ellipsearc.svg" *src-location*)))))
	 (button-pline (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/pline.svg" *src-location*)))))
	 (button-polygon (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/polygon.svg" *src-location*)))))
	 (button-point (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/point.svg" *src-location*)))))
	 (button-rectangle (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/rectangle.svg" *src-location*)))))
	 (button-spline (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/spline.svg" *src-location*)))))
	 (button-text (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/objects/text.svg" *src-location*)))))
         ;;;modify
	 (modify-expander (make-instance 'expander :expanded t :label "Modify"))
	 (modify-table (make-instance 'table :n-rows 3 :n-columns 4 :homogeneous nil))
	 (button-break (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_break.svg" *src-location*)))))
	 (button-erase (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_erase.svg" *src-location*)))))
	 (button-explode (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_explode.svg" *src-location*)))))
	 (button-extend (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_extend.svg" *src-location*)))))
	 (button-lengthen (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_lengthen.svg" *src-location*)))))
	 (button-move (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_move.svg" *src-location*)))))
	 (button-rotate (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_rotate.svg" *src-location*)))))
	 (button-scale (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_scale.svg" *src-location*)))))
	 (button-stretch (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_stretch.svg" *src-location*)))))
	 (button-trim (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/modify/mod_trim.svg" *src-location*)))))
         ;;;dimension
	 (dimension-expander (make-instance 'expander :expanded t :label "Dimension"))
	 (dimension-table (make-instance 'table :n-rows 3 :n-columns 4 :homogeneous nil))
	 (button-align (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimalign.svg" *src-location*)))))
	 (button-angular (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimangular.svg" *src-location*)))))
	 (button-baseline (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimbaseline.svg" *src-location*)))))
	 (button-center (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimcenter.svg" *src-location*)))))
	 (button-continue (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimcontinue.svg" *src-location*)))))
	 (button-diameter (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimdiameter.svg" *src-location*)))))
	 (button-horiz (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimhoriz.svg" *src-location*)))))
	 (button-leader (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimleader.svg" *src-location*)))))
	 (button-vert (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/dimension/dimvert.svg" *src-location*)))))
	 ;;;construct
	 (construct-expander (make-instance 'expander :expanded t :label "Construct"))
	 (construct-table (make-instance 'table :n-rows 2 :n-columns 4 :homogeneous nil))
	 (button-array-polar (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_array_polar.svg" *src-location*)))))
	 (button-array-rect (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_array_rect.svg" *src-location*)))))
	 (button-chamfer (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_chamfer.svg" *src-location*)))))
	 (button-copy (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_copy.svg" *src-location*)))))
	 (button-fillet (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_fillet.svg" *src-location*)))))
	 (button-mirror (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_mirror.svg" *src-location*)))))
	 (button-offset (make-instance 'button :image (make-instance 'image :file (namestring (merge-pathnames "graphics/construct/cons_offset.svg" *src-location*)))))
	 (full-window 0)
	 (term-file-name nil)
	  x y)
     (set-status-icon-tooltip icon "Main CAD menu")
     ;;;pack
     (container-add w v-box)
     (box-pack-start v-box toolbar :expand nil)
     (container-add v-box vpaned)
     (container-add vpaned h-box)
     (box-pack-start h-box menu-notebook :expand nil)
     (box-pack-start h-box draw-area :expand t)
     (container-add vpaned term-notebook)
     (box-pack-start term-vbox term-hbox :expand nil)
     (container-add term-vbox term-scrolled)
     (container-add term-scrolled term-text-view)
     (box-pack-start term-hbox term-new :expand nil)
     (box-pack-start term-hbox term-open :expand nil)
     (box-pack-start term-hbox term-save :expand nil)
     (box-pack-start term-hbox term-save-as :expand nil)
     (box-pack-start term-hbox term-eval :expand nil)
     (notebook-add-page menu-notebook
			tools-vbox
			(make-instance 'label :label "Tools"))
     (notebook-add-page menu-notebook
			(make-instance 'v-box)
			(make-instance 'label :label "Files"))
     (notebook-add-page menu-notebook
			(make-instance 'v-box)
			(make-instance 'label :label "Statistic"))
     (notebook-add-page term-notebook 
			term-vbox
			(make-instance 'label :label "Terminal"))
     (notebook-add-page term-notebook
			(make-instance 'v-box)
			(make-instance 'label :label "Palettes"))
     ;system 
     (container-add toolbar  button-save)
     (container-add toolbar button-save-as)
     (container-add toolbar button-new)
     (container-add toolbar button-open)
     (container-add toolbar button-print)
     (container-add toolbar button-print-prop)
     (container-add toolbar button-file-prop)
     (container-add toolbar button-layers)
     (container-add toolbar button-system-properties)
     (container-add toolbar button-color-selection)
     (container-add toolbar button-select-font)
     (container-add toolbar button-full)
     (container-add toolbar button-osnap)
     ;primitives
     (box-pack-start tools-vbox primitives-expander :expand nil)
     (container-add primitives-expander primitives-table)
     (table-attach primitives-table button-line 0 1 0 1)
     (table-attach primitives-table button-ray 1 2 0 1)
     (table-attach primitives-table button-construction 2 3 0 1)
     (table-attach primitives-table button-circle-radius 3 4 0 1)
     (table-attach primitives-table button-circle-2p 0 1 1 2)
     (table-attach primitives-table button-circle-3p 1 2 1 2)
     (table-attach primitives-table button-circle-diameter 2 3 1 2)
     (table-attach primitives-table button-circle-ttr 3 4 1 2)
     (table-attach primitives-table button-circle-ttt 0 1 2 3)
     (table-attach primitives-table button-arc 1 2 2 3)
     (table-attach primitives-table button-ellipse-center 2 3 2 3)
     (table-attach primitives-table button-ellipse-axis 3 4 2 3)
     (table-attach primitives-table button-ellipse-arc 0 1 3 4)
     (table-attach primitives-table button-pline 1 2 3 4)
     (table-attach primitives-table button-polygon 2 3 3 4)
     (table-attach primitives-table button-point 3 4 3 4)
     (table-attach primitives-table button-rectangle 0 1 4 5)
     (table-attach primitives-table button-spline 1 2 4 5)
     (table-attach primitives-table button-text 2 3 4 5)
     ;modify
     (box-pack-start tools-vbox modify-expander :expand nil)
     (container-add modify-expander modify-table)
     (table-attach modify-table button-break 0 1 0 1)
     (table-attach modify-table button-erase 1 2 0 1)
     (table-attach modify-table button-explode 2 3 0 1)
     (table-attach modify-table button-extend 3 4 0 1)
     (table-attach modify-table button-lengthen 0 1 1 2)
     (table-attach modify-table button-move 1 2 1 2)
     (table-attach modify-table button-rotate 2 3 1 2)
     (table-attach modify-table button-scale 3 4 1 2)
     (table-attach modify-table button-stretch 0 1 2 3)
     (table-attach modify-table button-trim 1 2 2 3)
     ;dimension
     (box-pack-start tools-vbox dimension-expander :expand nil)
     (container-add dimension-expander dimension-table)
     (table-attach dimension-table button-align 0 1 0 1)
     (table-attach dimension-table button-angular 1 2 0 1)
     (table-attach dimension-table button-baseline 2 3 0 1)
     (table-attach dimension-table button-center 3 4 0 1)
     (table-attach dimension-table button-continue 0 1 1 2)
     (table-attach dimension-table button-diameter 1 2 1 2)
     (table-attach dimension-table button-horiz 2 3 1 2)
     (table-attach dimension-table button-leader 3 4 1 2)
     (table-attach dimension-table button-vert 0 1 2 3)
     ;construct
     (box-pack-start tools-vbox construct-expander :expand nil)
     (container-add construct-expander construct-table)
     (table-attach construct-table button-array-polar 0 1 0 1)
     (table-attach construct-table button-array-rect 1 2 0 1)
     (table-attach construct-table button-chamfer 2 3 0 1)
     (table-attach construct-table button-copy 3 4 0 1)
     (table-attach construct-table button-fillet 0 1 1 2)
     (table-attach construct-table button-mirror 1 2 1 2)
     (table-attach construct-table button-offset 2 3 1 2)
     ;;;g-signals
     (gobject:g-signal-connect w "destroy" (lambda (b) (declare (ignore b)) 
						   (setf (status-icon-visible icon) nil)
						   (leave-gtk-main)))
     (gobject:g-signal-connect w "delete-event" (lambda (widget event)
					  (declare (ignore widget event))
					  (let ((dlg (make-instance 'message-dialog
								    :text "Are you sure?"
								    :buttons :yes-no)))
					    (let ((response (dialog-run dlg)))
					      (object-destroy dlg)
					      (not (eq :yes response))))))
     (gobject:g-signal-connect button-save "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-save-as "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-new "clicked" (lambda (w) (declare (ignore w)) (make-new-file-window)))
     (gobject:g-signal-connect button-open "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
;     (gobject:g-signal-connect button-print "clicked"
     (gobject:g-signal-connect button-print-prop "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-file-prop "clicked" (lambda (w) (declare (ignore w)) (file-properties-window)))
     (gobject:g-signal-connect button-color-selection "color-changed" (lambda (s) (declare (ignore s)) 
									      (unless (color-selection-adjusting-p button-color-selection) 
										(format t "color: ~A~%" (color-selection-current-color button-color-selection)))))
     (gobject:g-signal-connect button-select-font "font-set" (lambda (b) (declare (ignore b)) 
								     (format t "Chose font ~A~%" (font-button-font-name button-select-font))))
     (gobject:g-signal-connect button-system-properties "clicked" (lambda (w) (declare (ignore w)) (draw-properties-window)))
     (gobject:g-signal-connect button-layers "clicked" (lambda (w) (declare (ignore w)) (layers-window)))
     (gobject:g-signal-connect button-full "toggled" (lambda (b) (declare (ignore b))
							     (if (evenp full-window) (gtk-window-fullscreen w) (gtk-window-unfullscreen w))
							     (incf full-window)))
     (gobject:g-signal-connect button-osnap "clicked" (lambda (b) (declare (ignore b)) (osnap-window)))
  ;   (gobject:g-signal-connect button-line "clicked" (lambda (widget) (declare (ignore widget))
;							     (setf (cairo-w-draw-fn draw-area)
;								   (draw-line))))
     (gobject:g-signal-connect button-ray "clicked" (lambda (w) (declare (ignore w)) 
							    (coming-soon-window)))
     (gobject:g-signal-connect button-construction "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-radius "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-2p "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-3p "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-diameter "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-ttr "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-circle-ttt "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-arc "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-ellipse-center "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-ellipse-axis "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-ellipse-arc "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-pline "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-polygon "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-point "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-rectangle "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-spline "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-text "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-break "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-erase "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-explode "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-extend "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-lengthen "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-move "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-rotate "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-scale "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-stretch "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-trim "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-align "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-angular "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-baseline "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-center "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-continue "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-diameter "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-horiz "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-leader "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect button-vert "clicked" (lambda (w) (declare (ignore w)) (coming-soon-window)))
     (gobject:g-signal-connect term-new "clicked" (lambda (&rest args) (declare (ignore args)) 
							  (setf term-file-name nil
								(text-buffer-text (text-view-buffer term-text-view)) "")))
     (gobject:g-signal-connect term-save "clicked" (lambda (&rest args) (declare (ignore args)) 
							   (if term-file-name
							       (progn
								 (with-open-file (file term-file-name :direction :output :if-exists :supersede)
								   (write-string (text-buffer-text (text-view-buffer term-text-view)) file))))))
     (gobject:g-signal-connect term-save-as "clicked" (lambda (&rest args) (declare (ignore args)) 
							      (let ((d (make-instance 'file-chooser-dialog :action :save :title "Save file")))
								(when term-file-name (setf (file-chooser-filename d) term-file-name))
								(dialog-add-button d "gtk-save" :accept)
								(dialog-add-button d "gtk-cancel" :cancel)
								(if (eq :accept (dialog-run d))
								    (progn
								      (setf term-file-name (file-chooser-filename d))
								      (object-destroy d))
								    (object-destroy d)))))
     (gobject:g-signal-connect term-open "clicked" (lambda (&rest args) (declare (ignore args)) 
							   (let ((d (make-instance 'file-chooser-dialog :action :open :title "Open file")))
							     (when term-file-name (setf (file-chooser-filename d) term-file-name))
							     (dialog-add-button d "gtk-open" :accept)
							     (dialog-add-button d "gtk-cancel" :cancel)
							     (when (eq :accept (dialog-run d))
							       (setf term-file-name (file-chooser-filename d)
								     (text-buffer-text (text-view-buffer term-text-view)) (read-text-file term-file-name)))
							     (object-destroy d))))
     (gobject:g-signal-connect term-eval "clicked" (lambda (&rest args) (declare (ignore args)) 
							   (let ((buffer (text-view-buffer term-text-view)))
							     (multiple-value-bind (i1 i2) (text-buffer-get-selection-bounds buffer)
							       (when (and i1 i2)
								 (with-gtk-message-error-handler
								   (let* ((text (text-buffer-slice buffer i1 i2))
									  (value (eval (read-from-string text)))
									  (value-str (format nil "~A" value))
									  (pos (max (text-iter-offset i1) (text-iter-offset i2))))
								     (text-buffer-insert buffer " => " :position (text-buffer-get-iter-at-offset buffer pos))
								     (incf pos (length " => "))
								     (text-buffer-insert buffer value-str :position (text-buffer-get-iter-at-offset buffer pos)))))))))
     (gobject:connect-signal icon "activate" (lambda (i)
					       (declare (ignore i)) 
					       (menu-window)))
     (widget-show w)
     (setf (status-icon-screen icon) (gtk-window-screen w)))))

(defun run ()
  (main-window)
  (join-gtk-main)
  (quit))

(defun draw-space1 (w h)
  (set-source-rgb 1 1 1)
  (paint)
  (move-to (- w 320) (- h 50))
  (set-font-size 50)
  (set-source-rgb 0 0 1)
  (show-text "CL-CAD v0.1"))