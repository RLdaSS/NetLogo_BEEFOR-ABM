;; ATTENTION: to run this code using these datas attached with BEEFOR-ABM (GIS files), it is necessary to have at least 24GB of memory destined for NetLogo (less than 24GB error: OutOfMemoryError)
            ; to modify the NetLogo default (1GB of memory), access netlogo user manual 6.2.2
            ; if you prefer, you can reduce the size of the world and run the model with the smallest size or enter your GIS files at a smaller scale
;; world: NetLogo world
;; NetLogo world background color has been set to white
;;;; EXTENSIONS ;;;;
extensions [ gis csv vid ]
;;;; GLOBALS ;;;;
;; define global variables
globals [
  Resources
  Landcover
  OutputData-4List ;; to create a table in outputData-4 (BeePath)
  OutputData-5List ;; to create a table in no outputData-5 (VisitantBees)
  ProportionTraveledLandscape ;; to create outputData-6 (ProportionTraveledLandscape)
  TotalShades ;; the total number of shades (<= 200), BeeVisitGradient
  MidPointnlColor ;; the named NetLogo color at the midpoint (last digit is 5), BeeVisitGradient
  RandomSeed
  NumResourceFiles
  NumLandscapeFiles
  LoadSaveDirectoryFolder
]
;;;; AGENT DEFINITION ;;;;
;; define agent types
breed [ bees bee ] ;; creates the bee profiles
;; define bees variables ;; declaring all bee variables of BEEFOR SIMULATION
bees-own
[
  energy
  accumulated-energy
  step-count
  metabolism
  adjustment-metabolism
  real-x ;; the real x coord dist from origin ie ignoring wrapping around world
  real-y ;; the real y coord dist from origin ie ignoring wrapping around world
  max-flight-dist
  distance-traveled
  max-energy-per-bee
  my-home
  patch-visited
  xcor-list ;; to create a table in outputData-4 (BeePath)
  ycor-list ;; to create a table in outputData-4 (BeePath)
]
;; define patches variables  ;; declaring all patch variables
patches-own
[
  habitatcover
  resource-value
  my-agent
  energy-of-my-agent
  patch-visit-freq ;; absolute frequency in patch
  visitant-bees ;; outputData-5 (VisitantBees)
  sum-energy-of-my-agent ;; outputData-2
  sum-energy-of-my-agent2 ;; outputData-2
  round-sum-energy-of-my-agent ;; outputData-2
  round-sum-energy-of-my-agent2 ;; outputData-2
  max-accumulated-energy-patch ;; communication mode procedure
]
;; ===========================================================================
;;;; MODEL SETUP ;;;;
to setup
  clear-all
  set RandomSeed 1
  random-seed RandomSeed
  ; let start timer ;; start time
  set OutputData-4List [ [ "id_bee" "my_xcor" "my_ycor" ] ]
  set OutputData-5List [ [ "pcxor" "pycor" "id_visitant_bees" ] ]
  ifelse ( Display? = true ) [ display ] [ no-display ] ;; shut on/off the display to take much  patch-faster to run the code using switch in GUI
  ;; use input "EdgeSize" in inter patch-face of NetLogo
  resize-world EdgeSize * 0 ( EdgeSize * 1 )  ( EdgeSize * -1 ) EdgeSize * 0 ;; defines the edge size of the world and location of origin: corner top left
  set NumResourceFiles 1
  set NumLandscapeFiles 1
  prepare-outputData-3 ;; CALL A PROCEDURE
  prepare-outputData-6 ;; CALL A PROCEDURE
  setup-layers ;; CALL A PROCEDURE
  setup-patches ;; CALL A PROCEDURE
  reset-ticks
  if vid:recorder-status = "recording" [ vid:record-view ]
 ; let finish timer ;; finish time
 ; print ( word "that setup took " ( finish - start ) " seconds" )
end
to sub-setup
  clear-method ;; CALL A PROCEDURE
  random-seed RandomSeed
  ; let start timer ;; start time
  set OutputData-4List [ [ "id_bee" "my_xcor" "my_ycor" ] ]
  set OutputData-5List [ [ "pcxor" "pycor" "id_visitant_bees" ] ]
  ifelse ( Display? = true ) [ display ] [ no-display ]  ;; shut on/off the display to take much  patch-faster to run the code using switch in GUI
  ;; use input "EdgeSize" in inter patch-face of NetLogo
  resize-world EdgeSize * 0 ( EdgeSize * 1 )  ( EdgeSize * -1 ) EdgeSize * 0 ;; defines the edge size of the world and location of origin: corner top left
  prepare-outputData-3 ;; CALL A PROCEDURE
  prepare-outputData-6 ;; CALL A PROCEDURE
  setup-layers ;; CALL A PROCEDURE
  setup-patches ;; CALL A PROCEDURE
  reset-ticks
  if vid:recorder-status = "recording" [ vid:record-view ]
  ; let finish timer ;; finish time
  ; print ( word "that setup took " ( finish - start ) " seconds" )
end
to clear-method
  set Resources 0
  set Landcover 0
  ask patches
  [
    set patch-visit-freq 0
    set visitant-bees [ ]
    if any? bees-here
    [
      set my-agent [ who ] of bees-here
    ]
    set energy-of-my-agent [ ]
  ]
  clear-ticks
  clear-turtles
  clear-drawing
  clear-all-plots
  clear-output
end
to prepare-outputData-3
  if outputData-3? = true
  [
    let numLand word "_Landscape" NumLandscapeFiles
    let numResource word "_NDVI" NumResourceFiles
    let numSeed word "_seed" RandomSeed
    let numBeeSize ( word "_" BeeSize "mm" )
    let x EdgeSize
    set x ( ( ( x + 1 ) * 10 ) ) / 1000
    let numEdgeSize ( word "_" x "km" )
    carefully
    [ file-delete ( word NameOutfile-outputData-3 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) ]
    [ ]
    file-open ( word NameOutfile-outputData-3 numLand numResource numSeed numBeeSize numEdgeSize ".csv" )
    file-print ( word "id_bee,distance_traveled" )
    ; file-print "" ;; blank line
    file-close
  ]
end
to prepare-outputData-6
  if outputData-6? = true
  [
    let numLand word "_Landscape" NumLandscapeFiles
    let numResource word "_NDVI" NumResourceFiles
    let numSeed word "_seed" RandomSeed
    let numBeeSize ( word "_" BeeSize "mm" )
    let x EdgeSize
    set x ( ( ( x + 1 ) * 10 ) ) / 1000
    let numEdgeSize ( word "_" x "km" )
    carefully
    [ file-delete ( word NameOutfile-outputData-6 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) ]
    [ ]
    file-open ( word NameOutfile-outputData-6 numLand numResource numSeed numBeeSize numEdgeSize ".csv" )
    file-print ( word "id_bee,proportion_traveled_landscape" )
    ; file-print "" ;; blank line
    file-close
  ]
end
;; ===========================================================================
;;;; GIS MAP SETUP ;;;;
to setup-layers ;; load in the GIS datas for landscape
                ;; note that setting the coordinate system here is optional, as long as all of your datasets use the same coordinate system
  let num NumResourceFiles ;; number of NDVIs associated with each landcover, In the current configuration: NDVI1 represents the dry season and NDVI2 the wet season (Example: L1_NDVI1, L1_NDVI2,... L27_NDVI1, L27_NDVI2)
  let num2 NumLandscapeFiles ;; number of landcovers to be loaded in sequence. In the current configuration 27 landcovers
  set Resources gis:load-dataset ( word "./LAYERS/RESOURCES/L" num2 "_NDVI" num ".asc" ) ;; this loads a one map presenting a NDVI values: proxy of floral resources. The files must be named by a numerical sequence (Example: L1_NDVI1, L1_NDV12,... L27_NDVI1, L27_NDVI2)
  set Landcover gis:load-dataset ( word "./LAYERS/LANDCOVERS/L" num2 ".asc" ) ;; this loads a map presenting a landcover map: landscap. The files must be named by a numerical sequence (Example: L1, L2,... L27)
  ;; set the world envelope to the union of all of our dataset's envelopes
  gis:set-world-envelope gis:envelope-of Resources
  gis:apply-raster Resources resource-value
  gis:apply-raster Landcover habitatcover
  ;color-Resources
  ;color-Landcover
end
;to color-Resources ;; color the values of resource
;  ask patches
;  [
;    ;; low values of resource
;    ifelse resource-value <= 30 [ set pcolor gray ]
;    [ set pcolor green - 4 ] ;; high values of resource
;  ]
;end
;to color-Landcover ;; color the landcover
;  ask patches
;  [
;    (
;      ifelse
;      habitatcover = 1 [ set pcolor orange + 2.9 ] ;; crop rotation: functional patches
;      habitatcover = 2 [ set pcolor orange - 2 ] ;; perennial crop: functional patches
;      habitatcover = 3 [ set pcolor green + 1 ] ;; native grassland: functional patches
;      habitatcover = 4 [ set pcolor green - 1 ] ;; native shrubland: functional patches
;      habitatcover = 5 [ set pcolor green - 2.5 ] ;; native forest: functional patches
;      habitatcover = 6 [ set pcolor brown ] ;; environments that were regenerating, bare soil and roadsides: functional patches
;      habitatcover = 7 [ set pcolor blue ] ;; without floral cover (water / shadow): non-functional patches
;    )
;  ]
;end
;; ===========================================================================
;;;; PATCHES SETUP ;;;;
to setup-patches
  ;; use input "ViewPatchSize" in GUI
  set-patch-size ViewPatchSize ;; view patch size
  ;; below using the "sprout" in an orderly from the corner top left
  let coord-X min-pxcor
  let coord-Y max-pycor
  while [ coord-Y >= min-pycor ]
  [
    while [ coord-X <= max-pxcor ]
    [
      ask patch coord-X coord-Y
      [
        if habitatcover != 7 [ sprout-bees num-ForageBees [ setup-bees ] ]
        set patch-visit-freq 0
        set visitant-bees [ who ] of bees-here
        if any? bees-here
        [
          set my-agent [ who ] of bees-here
        ]
        set energy-of-my-agent [ ]
      ]
      set coord-X coord-X + 1
    ]
    set coord-Y coord-Y - 1
    set coord-X min-pxcor
  ]
  ; print "made it"
end
;; ===========================================================================
;;;; BEES SETUP ;;;;
to setup-bees   ;; bee procedure
 ifelse ExportViewBeeVisitGradient? = true
  [
    BeeVisitGradientProc ;; CALL A PROCEDURE
  ]
  [ ]
  set shape "mybee"
  set color yellow
  ; set size 1
  ; pen-down
  ; set pen-size 0.2
  set step-count 0 ;; the initial bee step count
  set accumulated-energy 0
  set distance-traveled  0
  set my-home patch-here
  ifelse [ resource-value ] of my-home > 30 [ set energy [ resource-value ] of patch-here ] [ set energy 0 ] ;; this sets the initial energy for all bees
  set patch-visited ( list patch-here )
  set xcor-list ( list xcor )
  set ycor-list ( list ycor )
  ;; RullsAllometricScales
  set max-flight-dist round ( ( 10 ^ ( - 0.760 + 2.313 * log BeeSize 10 ) ) * 1000 / GrainSize-m ) ;; maximum feeder training distance (m) based in Greenleaf et al., 2007
  set max-energy-per-bee round ( BeeSize * BeeCargoCapacity ) ;; BeeCargoCapacity was calculated based on honeybees (Southwick and D. Pimentel, 1981)
  set metabolism BeeMetabolism ;; this is the metabolic rate (how much energy they use at each step) based in honeybees (Southwick and D. Pimentel, 1981)
  set adjustment-metabolism  precision ( max-energy-per-bee / 7000 ) 1 ;; metabolism adjustment for other bees based on honeybees
  ; show adjustment-metabolism
  set real-x xcor
  set real-y ycor
end
;; ===========================================================================
;;;; BEES ACTIONS ;;;;
to go
  if NumLandscapeFiles = num-LandscapeFiles + 1 [ stop ]
  ; reset-timer
  ifelse ( Display? = true ) [ display ] [ no-display ]
  ComputingVisitantBeesProc ;; CALL A PROCEDURE
  InconePatchesProc ;; CALL A PROCEDURE
  CalcDistTraveled-and-%TraveledLandscapeProc ;; CALL A PROCEDURE
  ForageFocalPatchProc ;; CALL A PROCEDURE
  ProbBeeChangeDirectionProc ;; CALL A PROCEDURE
  FlyBackAndDepositResourcesProc ;; CALL A PROCEDURE
  CommunicationModeProc ;; CALL A PROCEDURE
  tick
  let n count bees
  if n = 0 and outputData-1? = true [ outputData-1 ] ;; CALL A PROCEDURE
  if n = 0 and outputData-2? = true [ outputData-2 ] ;; CALL A PROCEDURE
  if n = 0 and outputData-5? = true [ outputData-5 ] ;; CALL A PROCEDURE
  if ExportViewBeeVisitGradient? = true [ outputData-7 ] ;; CALL A PROCEDURE
  if n = 0
  [
    set RandomSeed RandomSeed + 1
    if RandomSeed = Repetitions + 1
    [
      set RandomSeed 1
      set NumResourceFiles NumResourceFiles + 1
      if NumResourceFiles = num-ResourceFiles + 1
      [
        set NumResourceFiles 1
        set NumLandscapeFiles NumLandscapeFiles + 1
        ask patches [ set sum-energy-of-my-agent 0 ]
        if NumLandscapeFiles = num-LandscapeFiles + 1 [ stop ]
      ]
    ]
    sub-setup
  ]
  ; print ( word "That tick took " timer " seconds" )
  if vid:recorder-status = "recording" [ vid:record-view ]
end
;; ===========================================================================
;; COMPUTING VISITANT BEES IN EACH PATCH PROCEDURE
to ComputingVisitantBeesProc ;; RUN A PROCEDURE
  ask patches
  [
    ask bees-here
    [
      set visitant-bees lput who visitant-bees
      ifelse ExportViewBeeVisitGradient? = true
      [
        BeeVisitGradientProc ;; CALL A PROCEDURE
      ]
      [ ]
    ]
  ]
end
;; ===========================================================================
;;; IN-CONE PATCHES PROCEDURE
to InconePatchesProc ;; RUN A PROCEDURE
  ask bees
  [
    let origin patch-here
    let availablePatch patches in-cone 2 90 with [ not member? self [ patch-visited ] of myself and resource-value > 30 ]
    let inconeAvailable count availablePatch
    ifelse inconeAvailable = 0
    [
      FlyAroundProc ;; CALL A PROCEDURE
    ]
    [
      let target max-one-of availablePatch [ resource-value ]
      face target move-to target
      set step-count step-count + 1
    ]
    if ( origin != patch-here )
    [
      ifelse Integer-4? = false
      [
        set xcor-list lput xcor xcor-list
        set ycor-list lput ycor ycor-list
      ]
      [
        set xcor-list lput round xcor xcor-list
        set ycor-list lput round ycor ycor-list
      ]
    ]
  ]
end
;; ===========================================================================
;; FLY AROUND PROCEDURE
to FlyAroundProc ;; RUN A PROCEDURE
  type-walk
end
to type-walk ;; select appropropriate step method based on the type-of-walk drop-down
             ;;; all the TypeWalk are random walks, take from the book OSullivan & Perry, 2013 and Newton et al., 2018
  (
    ifelse
    TypeWalk = "Levy walk"
    [
      set heading random-float 360
      let x1 xcor
      let y1 ycor
      let alfa 1.5
      let minstep 0.2
      let step-length r-levywalk 1 3.5 ;; if using the Levy walk, change the values
     ; print ( word "step-Levy-walk:" step-length )
     ; show step-length
      forward step-length
      let x2 xcor
      let y2 ycor
      let effective-step-length sqrt ( ( x2 - x1 ) ^ 2 + ( y2 - y1 ) ^ 2 )
      set step-count step-count + effective-step-length
      set distance-traveled distance-traveled - 1 + effective-step-length
    ]
    TypeWalk = "Simple" ;; move unit distance in a uniform-random direction
    [
      set heading random-float 360
      set real-x real-x + dx
      set real-y real-y + dy
      let x1 xcor
      let y1 ycor
      let step-length 2
     ; print ( word "step-lenght-simple:" step-length )
      forward step-length
      let x2 xcor
      let y2 ycor
      let effective-step-length sqrt ( ( x2 - x1 ) ^ 2 + ( y2 - y1 ) ^ 2 )
      set step-count step-count + effective-step-length
      set distance-traveled distance-traveled - 1 + effective-step-length
    ]
    TypeWalk = "Correlated directions" ;; move unit distance but direction is determined by turning from current direction
    [
      rt random-normal 0 StdevAngle
      set real-x real-x + dx
      set real-y real-y + dy
      let x1 xcor
      let y1 ycor
      let step-length 2
     ; print ( word "step-lenght-Correlateddirections:" step-length )
      forward step-length
      let x2 xcor
      let y2 ycor
      let effective-step-length sqrt ( ( x2 - x1 ) ^ 2 + ( y2 - y1 ) ^ 2 )
      set step-count step-count + effective-step-length
      set distance-traveled distance-traveled - 1 + effective-step-length
    ]
    TypeWalk = "Normally distributed step length 1"
    [
      set heading random-float 360
      let x1 xcor
      let y1 ycor
      let step-length abs random-normal 0 MeanStepLength
      ; print ( word "step-lenght-Normallydistributedsteplength1:" step-length )
      set real-x real-x + (dx * step-length)
      set real-y real-y + (dy * step-length)
      fd step-length
      let x2 xcor
      let y2 ycor
      let effective-step-length sqrt ( ( x2 - x1 ) ^ 2 + ( y2 - y1 ) ^ 2 )
      set step-count step-count + effective-step-length
      set distance-traveled distance-traveled - 1 + effective-step-length
    ]
    TypeWalk = "Normally distributed step length 2"
    [
      let turn 0
      let randBar random 628 + 1 ;; randomly chosen bar from the empirical turning angle histogram searching honeybees with a total of 628 turning angles (derived from Becher et al 2016))
      (
        ifelse
        randBar >= 1 and randBar < 92 [ set turn 0 + random-float 10 ]
        randBar >= 92 and randBar < 144 [ set turn 10 + random-float 10 ]
        randBar >= 144 and randBar < 206 [ set turn 20 + random-float 10 ]
        randBar >= 206 and randBar < 262 [ set turn 30 + random-float 10 ]
        randBar >= 262 and randBar < 302 [ set turn 40 + random-float 10 ]
        randBar >= 302 and randBar < 343 [ set turn 50 + random-float 10 ]
        randBar >= 343 and randBar < 363 [ set turn 60 + random-float 10 ]
        randBar >= 363 and randBar < 396 [ set turn 70 + random-float 10 ]
        randBar >= 396 and randBar < 419 [ set turn 80 + random-float 10 ]
        randBar >= 419 and randBar < 440 [ set turn 90 + random-float 10 ]
        randBar >= 440 and randBar < 456 [ set turn 100 + random-float 10 ]
        randBar >= 456 and randBar < 483 [ set turn 110 + random-float 10 ]
        randBar >= 483 and randBar < 506 [ set turn 120 + random-float 10 ]
        randBar >= 506 and randBar < 526 [ set turn 130 + random-float 10 ]
        randBar >= 526 and randBar < 542 [ set turn 140 + random-float 10 ]
        randBar >= 542 and randBar < 570 [ set turn 150 + random-float 10 ]
        randBar >= 570 and randBar < 599 [ set turn 160 + random-float 10 ]
        randBar >= 599 and randBar <= 628 [ set turn 170 + random-float 10 ]
      )
      if random-float 1 > 0.5 [ set turn turn * -1 ]
      rt turn ;; this applies correlated direction instead of fully random degree angle, based on empirical data for turn angles
      if CorrelatedDirection? = true [ set turn random-normal 0 StdevAngle ] ;; rt random-normal 0 StdevAngle ; this option would activate the slider for turn angle and apply correlated direction
      rt turn
      if RandomWalk? = true [ set turn random-float 360 ] ;; uncorrelated random walk
      rt turn
      if FixTurningAngle? = true [ set turn FixRightTurn ]
      rt turn
      let x1 xcor
      let y1 ycor
      let step-length abs random-normal 0 MeanStepLength
     ; print ( word "step-lenght-Normallydistributedsteplength2:" step-length )
      set real-x real-x + ( dx * step-length )
      set real-y real-y + ( dy * step-length )
      fd step-length
      let x2 xcor
      let y2 ycor
      let effective-step-length sqrt ( ( x2 - x1 ) ^ 2 + ( y2 - y1 ) ^ 2 )
      set step-count step-count + effective-step-length
      set distance-traveled distance-traveled - 1 + effective-step-length
    ]
    TypeWalk = "Normally distributed step length 3"
    [
      let turn 0
      let randBar random 214 + 1 ;; randomly chosen bar from the empirical turning angle histogram searching bumblebees with a total of 214 turning angles (derived from Becher et al 2016))
      (
        ifelse
        randBar >= 1 and randBar < 24 [ set turn 0 + random-float 10 ]
        randBar >= 24 and randBar < 36 [ set turn 10 + random-float 10 ]
        randBar >= 36 and randBar < 45 [ set turn 20 + random-float 10 ]
        randBar >= 45 and randBar < 58 [ set turn 30 + random-float 10 ]
        randBar >= 58 and randBar < 73 [ set turn 40 + random-float 10  ]
        randBar >= 73 and randBar < 81 [ set turn 50 + random-float 10 ]
        randBar >= 81 and randBar < 86 [ set turn 60 + random-float 10 ]
        randBar >= 86 and randBar < 97 [ set turn 70 + random-float 10 ]
        randBar >= 97 and randBar < 107 [ set turn 80 + random-float 10 ]
        randBar >= 107 and randBar < 112 [ set turn 90 + random-float 10 ]
        randBar >= 112 and randBar < 124 [ set turn 100 + random-float 10 ]
        randBar >= 124 and randBar < 133 [ set turn 110 + random-float 10 ]
        randBar >= 133 and randBar < 143 [ set turn 120 + random-float 10 ]
        randBar >= 143 and randBar < 154 [ set turn 130 + random-float 10 ]
        randBar >= 154 and randBar < 166 [ set turn 140 + random-float 10 ]
        randBar >= 166 and randBar < 178 [ set turn 150 + random-float 10 ]
        randBar >= 178 and randBar < 192 [ set turn 160 + random-float 10 ]
        randBar >= 192 and randBar <= 214 [ set turn 170 + random-float 10 ]
      )
      if random-float 1 > 0.5 [ set turn turn * -1 ]
      rt turn ;; this applies correlated direction instead of fully random degree angle, based on empirical data for turn angles
      if CorrelatedDirection? = true [ set turn random-normal 0 StdevAngle ] ;; rt random-normal 0 StdevAngle ; this option would activate the slider for turn angle and apply correlated direction
      rt turn
      if RandomWalk? = true [ set turn random-float 360 ] ;; uncorrelated random walk
      rt turn
      if FixTurningAngle? = true [ set turn FixRightTurn ]
      rt turn
      let x1 xcor
      let y1 ycor
      let step-length abs random-normal 0 MeanStepLength
     ; print ( word "step-lenght-Normallydistributedsteplength3:" step-length )
      set real-x real-x + ( dx * step-length )
      set real-y real-y + ( dy * step-length )
      fd step-length
      let x2 xcor
      let y2 ycor
      let effective-step-length sqrt ( ( x2 - x1 ) ^ 2 + ( y2 - y1 ) ^ 2 )
      set step-count step-count + effective-step-length
      set distance-traveled distance-traveled - 1 + effective-step-length
    ]
    TypeWalk = "Exponentially distributed step length"
    [
      set heading random-float 360
      let x1 xcor
      let y1 ycor
      let step-length random-exponential MeanStepLength
     ; print (word "step-lenght-Exponentially-distributed-step-length:" step-length)
      set real-x real-x + ( dx * step-length )
      set real-y real-y + ( dy * step-length )
      fd step-length
      let x2 xcor
      let y2 ycor
      let effective-step-length sqrt ( ( x2 - x1 ) ^ 2 + ( y2 - y1 ) ^ 2 )
      set step-count step-count + effective-step-length
      set distance-traveled distance-traveled - 1 + effective-step-length
    ]
    TypeWalk = "Cauchy distributed step length"
    [
      set heading random-float 360
      let x1 xcor
      let y1 ycor
      let step-length r-cauchy 0 1 ;; original version was 0 1, but can limit the overall number of long step lengths by reducing the second figure, if you want change the values
     ; print ( word "step-lenght-Cauchy-distributed-step-length:" step-length )
      set real-x real-x + ( dx * step-length )
      set real-y real-y + ( dy * step-length )
      fd step-length
      let x2 xcor
      let y2 ycor
      let effective-step-length sqrt ( ( x2 - x1 ) ^ 2 + ( y2 - y1 ) ^ 2 )
      set step-count step-count + effective-step-length
      set distance-traveled distance-traveled - 1 + effective-step-length
    ]
  )
end
to-report r-levywalk [ minstep alpha ]
  report minstep * ( random-float 1 ) ^ ( -1 / alpha )
end
to-report r-cauchy [ loc scl ]
  let x ( pi * ( random-float 1 ) ) ;; NetLogo tan takes degrees not radians
  report loc + scl * tan ( x * ( 180 / pi ) )
end
;; ===========================================================================
;; CALCULE DISTANCE AND PROPORTION OF TRAVELED LANDSCAPE PROCEDURE
to CalcDistTraveled-and-%TraveledLandscapeProc ;; RUN A PROCEDURE
  ask bees
  [
    set distance-traveled distance-traveled + 1
    set ProportionTraveledLandscape ( distance-traveled * 100 / max-flight-dist )
  ]
end
;; ===========================================================================
;; FORAGE FOCAL PATCH PROCEDURE
to ForageFocalPatchProc ;; RUN A PROCEDURE
  ask bees
  [
    if [ resource-value ] of patch-here > 30
    [
      if not member? patch-here patch-visited
      [
        let resource [ resource-value ] of patch-here
        set energy energy + resource
        set patch-visited lput patch-here patch-visited
        set patch-visited get-last 10 patch-visited
        ; print patch-visited
      ]
    ]
    ;; energy calculation
    set accumulated-energy ( energy - ( step-count * metabolism * adjustment-metabolism ) )
  ]
end
to-report get-last [ num lst ]
  let b length lst
  let a b - num
  report sublist lst ( ifelse-value ( a < 0 ) [ 0 ] [ a ] ) b
end
;; ===========================================================================
;; BEE CHANGE DIRECTION PROCEDURE
to ProbBeeChangeDirectionProc ;; RUN A PROCEDURE
  ifelse ProbBeeChangeDirection? = true
  [
    ask bees [
      let b random-float 1.01
      ; print b
      ifelse b <= DirectionProbability
      [
        let counter 0
        let old-patch patch-here
        let target one-of neighbors
        face target move-to target
        let new-patch patch-here
        if ( old-patch = new-patch )
        [
          set counter counter + 1
        ]
        if [ resource-value ] of patch-here > 30
        [
          if not member? patch-here patch-visited
          [
            let resource [ resource-value ] of patch-here
            set energy energy + resource
            set patch-visited lput patch-here patch-visited
            set patch-visited get-last2 10 patch-visited
            ; print patch-visited
          ]
        ]
        ;; energy calculation
        set accumulated-energy ( energy - ( step-count * metabolism * adjustment-metabolism ) )
      ]
      [ ]
    ]
  ]
  [ ]
end
to-report get-last2 [ num lst ]
  let b length lst
  let a b - num
  report sublist lst ( ifelse-value ( a < 0 ) [ 0 ] [ a ] ) b
end
;; ===========================================================================
;; FLY BACK AND DEPOSIT RESOURCES PROCEDURE
to FlyBackAndDepositResourcesProc ;; RUN A PROCEDURE
  ask bees
  [
    if  energy >= max-energy-per-bee
    [
      set energy max-energy-per-bee
      ;; energy calculation
      set accumulated-energy ( energy - ( step-count * metabolism * adjustment-metabolism ) )
      let x accumulated-energy
      ask my-home
      [
        set energy-of-my-agent lput x energy-of-my-agent
      ]
      if outputData-3? = true [ outputData-3 ] ;; CALL A PROCEDURE
      if outputData-4? = true [ outputData-4 ] ;; CALL A PROCEDURE
      if outputData-6? = true [ outputData-6 ] ;; CALL A PROCEDURE
      die
    ]
    if  distance-traveled >= max-flight-dist
    [
      set distance-traveled max-flight-dist
      ;; energy calculation
      set accumulated-energy ( energy - ( step-count * metabolism * adjustment-metabolism ) )
      let x accumulated-energy
      ask my-home
      [
        set energy-of-my-agent lput x energy-of-my-agent
      ]
      if outputData-3? = true [ outputData-3 ] ;; CALL A PROCEDURE
      if outputData-4? = true [ outputData-4 ] ;; CALL A PROCEDURE
      if outputData-6? = true [ outputData-6 ] ;; CALL A PROCEDURE
      die
    ]
  ]
end
;; ===========================================================================
;; BEE VISIT GRADIENT PROCEDURE
to BeeVisitGradientProc ;; RUN A PROCEDURE
  set MidPointnlColor orange
  set TotalShades 100
  hide-turtle
  pen-erase
  ifelse habitatcover = 7
  [
    set pcolor white
  ]
  [
    set patch-visit-freq patch-visit-freq + 1
    ask patch-here [ recolor-patch ]
  ]
end
to recolor-patch
  set pcolor make-nl-color-shade MidpointnlColor patch-visit-freq TotalShades
end
to-report make-nl-color-shade [ nl-color shade-value num-shades]
  ;; shade-value is forced to be between 0 and num-shades
  set shade-value min list num-shades max list 0 shade-value
  report scale-color nl-color shade-value num-shades 0
end
;; ===========================================================================
;; COMUNICATION MODE PROCEDURE
to CommunicationModeProc ;; RUN A PROCEDURE
  if CommunicationMode? = true
  [
    let coord-X min-pxcor
    let coord-Y max-pycor
    while [ coord-Y >= min-pycor ]
    [
      while [ coord-X <= max-pxcor ]
      [
        ask patch coord-X coord-Y
        [
        let mylist-accumulated-energy [ 0 ]
          if length energy-of-my-agent > 0 [ set mylist-accumulated-energy sort-by < energy-of-my-agent ]
          ; show mylist-accumulated-energy
          set max-accumulated-energy-patch last mylist-accumulated-energy
          ; show max-accumulated-energy-patch
          set max-accumulated-energy-patch max-accumulated-energy-patch * Numbers
          ; show max-accumulated-energy-patch
        ]
        set coord-X coord-X + 1
      ]
      set coord-Y coord-Y - 1
      set coord-X min-pxcor
    ]
  ]
end
;; ===========================================================================
;;;;;;;;;;;;;;;;  WRITING FILES ;;;;;;;;;;;;;;;;;;;;;;;;
;; RUN A PROCEDURE
to outputData-1 ;; AccumulateResource
  (
    ifelse
    Choose-outputData-1 = "Sum"
    [
      ifelse Integer-1? = false
      [
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent
          ]
        ]
        if NumResourceFiles = num-ResourceFiles
        [
          let sumName ( word "Sum" )
          let numLand word "_Landscape" NumLandscapeFiles
          let numSumResource ( word "_sum-of-" NumResourceFiles "NDVIs" )
          let numSumSeed ( word "-and-" Repetitions "seeds" )
          let numBeeSize ( word "_" BeeSize "mm" )
          let x EdgeSize
          set x ( ( ( x + 1 ) * 10 ) ) / 1000
          let numEdgeSize ( word "_" x "km" )
          ;; below export csv fileS
          ; carefully
          ; [ file-delete ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv" ) ]
          ; [ ]
          ; file-open (word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv")
          ; file-print ( word "pxcor,pycor,sum_accumulated_resource" )
          ; foreach sort patches
          ; [
          ;  t ->
          ; ask t
          ; [
          ;  file-print ( word pxcor "," pycor "," sum-energy-of-my-agent )
          ; ]
          ; ]
          ; file-print "" ;; blank line
          ; file-close
          ;; below export ascii files
          carefully
          [ file-delete ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" ) ]
          [ ]
          let output-data1 gis:patch-dataset sum-energy-of-my-agent
          gis:store-dataset output-data1 ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" )
        ]
      ]
      [
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent
          ]
        ]
        if NumResourceFiles = num-ResourceFiles
        [
          let sumName ( word "Sum" )
          let numLand word "_Landscape" NumLandscapeFiles
          let numSumResource ( word "_sum-of-" NumResourceFiles "NDVIs" )
          let numSumSeed ( word "-and-" Repetitions "seeds" )
          let numBeeSize ( word "_" BeeSize "mm" )
          let x EdgeSize
          set x ( ( ( x + 1 ) * 10 ) ) / 1000
          let numEdgeSize ( word "_" x "km" )
          ;; below export csv fileS
          ; carefully
          ; [ file-delete ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv" ) ]
          ; [ ]
          ; file-open (word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv")
          ; file-print ( word "pxcor,pycor,sum_accumulated_resource" )
          ; foreach sort patches
          ; [
          ;  t ->
          ; ask t
          ; [
          ;  file-print ( word pxcor "," pycor "," round sum-energy-of-my-agent )
          ; ]
          ; ]
          ; file-print "" ;; blank line
          ; file-close
          ;; below export ascii fileS
          carefully
          [ file-delete ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" ) ]
          [ ]
          ask patches
          [
            set round-sum-energy-of-my-agent round sum-energy-of-my-agent
          ]
          let output-data1 gis:patch-dataset round-sum-energy-of-my-agent
          gis:store-dataset output-data1 ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" )
        ]
      ]
    ]
    Choose-outputData-1 = "Average"
    [
      ifelse Integer-1? = false
      [
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent
          ]
        ]
        if NumResourceFiles = num-ResourceFiles
        [
          let averageName ( word "Average" )
          let numLand word "_Landscape" NumLandscapeFiles
          let numSumResource ( word "_average-of-" NumResourceFiles "NDVIs" )
          let numSumSeed ( word "-and-" Repetitions "seeds" )
          let numBeeSize ( word "_" BeeSize "mm" )
          let x EdgeSize
          set x ( ( ( x + 1 ) * 10 ) ) / 1000
          let numEdgeSize ( word "_" x "km" )
          ;; below export csv files
          ; carefully
          ; [ file-delete ( word averageName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv" ) ]
          ; [ ]
          ; file-open (word averageName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv")
          ; file-print ( word "pxcor,pycor,average_accumulated_resource" )
          ; foreach sort patches
          ; [
          ;  t ->
          ; ask t
          ; [
          ;  file-print ( word pxcor "," pycor "," ( sum-energy-of-my-agent  / Repetitions ) )
          ; ]
          ; ]
          ; file-print "" ;; blank line
          ; file-close
          ;; below export ascii fileS
          carefully
          [ file-delete ( word averageName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" ) ]
          [ ]
          let output-data1 gis:patch-dataset sum-energy-of-my-agent
          gis:store-dataset output-data1 ( word averageName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" )
        ]
      ]
      [
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent
          ]
        ]
        if NumResourceFiles = num-ResourceFiles
        [
          let averageName ( word "Average" )
          let numLand word "_Landscape" NumLandscapeFiles
          let numSumResource ( word "_average-of-" NumResourceFiles "NDVIs" )
          let numSumSeed ( word "-and-" Repetitions "seeds" )
          let numBeeSize ( word "_" BeeSize "mm" )
          let x EdgeSize
          set x ( ( ( x + 1 ) * 10 ) ) / 1000
          let numEdgeSize ( word "_" x "km" )
          ;; below export csv files
          ; carefully
          ; [ file-delete ( word averageName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv" ) ]
          ; [ ]
          ; file-open (word averageName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv")
          ; file-print ( word "pxcor,pycor,average_accumulated_resource" )
          ; foreach sort patches
          ; [
          ;  t ->
          ; ask t
          ; [
          ;  file-print ( word pxcor "," pycor "," ( round ( sum-energy-of-my-agent  / Repetitions ) ) )
          ; ]
          ; ]
          ; file-print "" ;; blank line
          ; file-close
          ;; below ascii files
          carefully
          [ file-delete ( word averageName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" ) ]
           [ ]
          ask patches
          [
            set round-sum-energy-of-my-agent round sum-energy-of-my-agent
          ]
          let output-data1 gis:patch-dataset round-sum-energy-of-my-agent
          gis:store-dataset output-data1 ( word averageName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" )
        ]
      ]
    ]
    Choose-outputData-1 = "Accumulated resource-i"
    [
      ifelse Integer-1? = false
      [
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent sum energy-of-my-agent
          ]
        ]
        let numLand word "-i_Landscape" NumLandscapeFiles
        let numResource word "_NDVI" NumResourceFiles
        let numSeed word "_seed" RandomSeed
        let numBeeSize ( word "_" BeeSize "mm" )
        let x EdgeSize
        set x ( ( ( x + 1 ) * 10 ) ) / 1000
        let numEdgeSize ( word "_" x "km" )
        ;; below export csv files
        ; carefully
        ; [ file-delete ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) ]
        ; [ ]
        ; file-open ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".csv" )
        ; file-print ( word "pxcor,pycor,accumulated_resource-i" )
        ; foreach sort patches
        ; [
        ;  t ->
        ; ask t
        ; [
        ;  file-print ( word pxcor "," pycor "," sum-energy-of-my-agent )
        ; ]
        ; ]
        ; file-print "" ;; blank line
        ; file-close
        ;; below export ascii files
        carefully
        [ file-delete ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".asc" ) ]
        [ ]
        let output-data1 gis:patch-dataset sum-energy-of-my-agent
        gis:store-dataset output-data1 ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".asc" )
      ]
      [
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent sum energy-of-my-agent
          ]
        ]
        let numLand word "-i_Landscape" NumLandscapeFiles
        let numResource word "_NDVI" NumResourceFiles
        let numSeed word "_seed" RandomSeed
        let numBeeSize ( word "_" BeeSize "mm" )
        let x EdgeSize
        set x ( ( ( x + 1 ) * 10 ) ) / 1000
        let numEdgeSize ( word "_" x "km" )
        ;; below export csv files
        ; carefully
        ; [ file-delete ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) ]
        ; [ ]
        ; file-open ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".csv" )
        ; file-print ( word "pxcor,pycor,accumulated_resource-i" )
        ; foreach sort patches
        ; [
        ;  t ->
        ; ask t
        ; [
        ;  file-print ( word pxcor "," pycor "," round sum-energy-of-my-agent )
        ; ]
        ; ]
        ; file-print "" ;; blank line
        ; file-close
        ;; below export ascii files
        carefully
        [ file-delete ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".asc" ) ]
        [ ]
        ask patches
        [
          set round-sum-energy-of-my-agent round sum-energy-of-my-agent
        ]
        let output-data1 gis:patch-dataset round-sum-energy-of-my-agent
        gis:store-dataset output-data1 ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".asc" )
      ]
    ]
    Choose-outputData-1 = "Sum and accumulated resource-i"
    [
      ifelse Integer-1? = false
      [
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent
          ]
        ]
        if NumResourceFiles = num-ResourceFiles
        [
          let sumName ( word "Sum" )
          let numLand word "_Landscape" NumLandscapeFiles
          let numSumResource ( word "_sum-of-" NumResourceFiles "NDVIs" )
          let numSumSeed ( word "-and-" Repetitions "seeds" )
          let numBeeSize ( word "_" BeeSize "mm" )
          let x EdgeSize
          set x ( ( ( x + 1 ) * 10 ) ) / 1000
          let numEdgeSize ( word "_" x "km" )
          ;; below export csv files
          ; carefully
          ; [ file-delete ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv" ) ]
          ; [ ]
          ; file-open (word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv")
          ; file-print ( word "pxcor,pycor,sum_accumulated_resource" )
          ; foreach sort patches
          ; [
          ;  t ->
          ; ask t
          ; [
          ;  file-print ( word pxcor "," pycor "," sum-energy-of-my-agent )
          ; ]
          ; ]
          ; file-print "" ;; blank line
          ; file-close
          ;; below export ascii files
          carefully
          [ file-delete ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" ) ]
          [ ]
          let output-data1 gis:patch-dataset sum-energy-of-my-agent
          gis:store-dataset output-data1 ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" )
        ]
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent2 sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent2 sum energy-of-my-agent
          ]
        ]
        let numLand word "-i_Landscape" NumLandscapeFiles
        let numResource word "_NDVI" NumResourceFiles
        let numSeed word "_seed" RandomSeed
        let numBeeSize ( word "_" BeeSize "mm" )
        let x EdgeSize
        set x ( ( ( x + 1 ) * 10 ) ) / 1000
        let numEdgeSize ( word "_" x "km" )
        ;; below export csv files
        ; carefully
        ; [ file-delete ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) ]
        ; [ ]
        ; file-open ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".csv" )
        ; file-print ( word "pxcor,pycor,accumulated_resource-i" )
        ; foreach sort patches
        ; [
        ;  t ->
        ; ask t
        ; [
        ;  file-print ( word pxcor "," pycor "," sum-energy-of-my-agent2 )
        ; ]
        ; ]
        ; file-print "" ;; blank line
        ; file-close
        ;; below export ascii files
        carefully
        [ file-delete ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".asc" ) ]
        [ ]
        let output-data1 gis:patch-dataset sum-energy-of-my-agent2
        gis:store-dataset output-data1 ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".asc" )
      ]
      [
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent sum-energy-of-my-agent + sum energy-of-my-agent
          ]
        ]
        if NumResourceFiles = num-ResourceFiles
        [
          let sumName ( word "Sum" )
          let numLand word "_Landscape" NumLandscapeFiles
          let numSumResource ( word "_sum-of-" NumResourceFiles "NDVIs" )
          let numSumSeed ( word "-and-" Repetitions "seeds" )
          let numBeeSize ( word "_" BeeSize "mm" )
          let x EdgeSize
          set x ( ( ( x + 1 ) * 10 ) ) / 1000
          let numEdgeSize ( word "_" x "km" )
          ;; below export csv files
          ; carefully
          ; [ file-delete ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv" ) ]
          ; [ ]
          ; file-open (word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".csv")
          ; file-print ( word "pxcor,pycor,sum_accumulated_resource" )
          ; foreach sort patches
          ; [
          ;  t ->
          ; ask t
          ; [
          ;  file-print ( word pxcor "," pycor "," round sum-energy-of-my-agent )
          ; ]
          ; ]
          ; file-print "" ;; blank line
          ; file-close
          ;; below export ascii files
          carefully
          [ file-delete ( word sumName NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" ) ]
          [ ]
          ask patches
          [
            set round-sum-energy-of-my-agent round sum-energy-of-my-agent
          ]
          let output-data1 gis:patch-dataset round-sum-energy-of-my-agent
          gis:store-dataset output-data1 ( word NameOutfile-outputData-1 numLand numSumResource numSumSeed numBeeSize numEdgeSize ".asc" )
        ]
        ifelse CommunicationMode? = true
        [
          ask patches
          [
            set sum-energy-of-my-agent2 sum energy-of-my-agent + max-accumulated-energy-patch
          ]
        ]
        [
          ask patches
          [
            set sum-energy-of-my-agent2 sum energy-of-my-agent
          ]
        ]
        let numLand word "-i_Landscape" NumLandscapeFiles
        let numResource word "_NDVI" NumResourceFiles
        let numSeed word "_seed" RandomSeed
        let numBeeSize ( word "_" BeeSize "mm" )
        let x EdgeSize
        set x ( ( ( x + 1 ) * 10 ) ) / 1000
        let numEdgeSize ( word "_" x "km" )
        ;; below export csv files
        ; carefully
        ; [ file-delete ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) ]
        ; [ ]
        ; file-open ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".csv" )
        ; file-print ( word "pxcor,pycor,accumulated_resource-i" )
        ; foreach sort patches
        ; [
        ;  t ->
        ; ask t
        ; [
        ;  file-print ( word pxcor "," pycor "," round sum-energy-of-my-agent2 )
        ; ]
        ; ]
        ; file-print "" ;; blank line
        ; file-close
        ;; below export ascii files
        carefully
        [ file-delete ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".asc" ) ]
        [ ]
        ask patches
        [
          set round-sum-energy-of-my-agent2 round sum-energy-of-my-agent2
        ]
        let output-data1 gis:patch-dataset round-sum-energy-of-my-agent2
        gis:store-dataset output-data1 ( word NameOutfile-outputData-1 numLand numResource numSeed numBeeSize numEdgeSize ".asc" )
      ]
    ]
  )
end
to outputData-2 ;; PatchVisitAbsoluteFrequency
  ask patches [ set patch-visit-freq length ( remove-duplicates visitant-bees ) ]
  let numLand word "_Landscape" NumLandscapeFiles
  let numResource word "_NDVI" NumResourceFiles
  let numSeed word "_seed" RandomSeed
  let numBeeSize ( word "_" BeeSize "mm" )
  let x EdgeSize
  set x ( ( ( x + 1 ) * 10 ) ) / 1000
  let numEdgeSize ( word "_" x "km" )
  ;; below export csv files
  ; carefully
  ; [ file-delete ( word NameOutfile-outputData-2 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) ]
  ; [ ]
  ; file-open ( word NameOutfile-outputData-2 numLand numResource numSeed numBeeSize numEdgeSize ".csv" )
  ; file-print ( "pxcor,pycor,patch_visit_freq" )
  ; foreach sort patches
  ;  [
  ;   t ->
  ;  ask t
  ; [
  ;  file-print ( word pxcor "," pycor "," patch-visit-freq )
  ; ]
  ; ]
  ; file-print "" ;; blank line
  ; file-close
  ;; below export ascii files
  carefully
  [ file-delete ( word NameOutfile-outputData-2 numLand numResource numSeed numBeeSize numEdgeSize ".asc" ) ]
  [ ]
  let output-data2 gis:patch-dataset patch-visit-freq
  gis:store-dataset output-data2 ( word NameOutfile-outputData-2 numLand numResource numSeed numBeeSize numEdgeSize ".asc" )
end
to outputData-3 ;; BeeDistanceTraveled
  let numLand word "_Landscape" NumLandscapeFiles
  let numResource word "_NDVI" NumResourceFiles
  let numSeed word "_seed" RandomSeed
  let numBeeSize ( word "_" BeeSize "mm" )
  let x EdgeSize
  set x ( ( ( x + 1 ) * 10 ) ) / 1000
  let numEdgeSize ( word "_" x "km" )
  file-open ( word NameOutfile-outputData-3 numLand numResource numSeed numBeeSize numEdgeSize ".csv" )
  ifelse Integer-3? = false
  [
    file-print ( word who "," distance-traveled )
  ]
  [
    file-print ( word who "," round distance-traveled )
  ]
  file-close
end
to outputData-4 ;; BeePath
  let numLand word "_Landscape" NumLandscapeFiles
  let numResource word "_NDVI" NumResourceFiles
  let numSeed word "_seed" RandomSeed
  let numBeeSize ( word "_" BeeSize "mm" )
  let x EdgeSize
  set x ( ( ( x + 1 ) * 10 ) ) / 1000
  let numEdgeSize ( word "_" x "km" )
  carefully
  [ file-delete ( word NameOutfile-outputData-4 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) ]
  [ ]
  let cur-who-list n-values ( length xcor-list ) [ who ]
  ( foreach cur-who-list xcor-list ycor-list
    [
      [ a b c ] ->
      let to-append ( list a b c )
      set OutputData-4List lput to-append OutputData-4List
    ]
  )
  csv:to-file ( word NameOutfile-outputData-4 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) OutputData-4List
end
to outputData-5 ;; VisitantBees
  let numLand word "_Landscape" NumLandscapeFiles
  let numResource word "_NDVI" NumResourceFiles
  let numSeed word "_seed" RandomSeed
  let numBeeSize ( word "_" BeeSize "mm" )
  let x EdgeSize
  set x ( ( ( x + 1 ) * 10 ) ) / 1000
  let numEdgeSize ( word "_" x "km" )
  carefully
  [ file-delete ( word NameOutfile-outputData-5 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) ]
  [ ]
  foreach sort patches
  [
    t ->
    let visitants remove-duplicates [ visitant-bees ] of t
    let pxcor-list n-values ( length visitants ) [ [ pxcor ] of t ]
    let pycor-list n-values ( length visitants ) [ [ pycor ] of t ]
    (
      foreach pxcor-list pycor-list visitants
      [
        [ a b c ] ->
        let to-append ( list a b c )
        set OutputData-5List lput to-append OutputData-5List
      ]
    )
  ]
  csv:to-file ( word NameOutfile-outputData-5 numLand numResource numSeed numBeeSize numEdgeSize ".csv" ) OutputData-5List
end
to outputData-6 ;; ProportionTraveledLandscape
  let numLand word "_Landscape" NumLandscapeFiles
  let numResource word "_NDVI" NumResourceFiles
  let numSeed word "_seed" RandomSeed
  let numBeeSize ( word "_" BeeSize "mm" )
  let x EdgeSize
  set x ( ( ( x + 1 ) * 10 ) ) / 1000
  let numEdgeSize ( word "_" x "km" )
  file-open ( word NameOutfile-outputData-6 numLand numResource numSeed numBeeSize numEdgeSize ".csv" )
  ifelse Integer-6? = false
  [
    file-print ( word who "," ProportionTraveledLandscape )
  ]
  [
    file-print ( word who "," round ProportionTraveledLandscape )
  ]
  file-close
end
to outputData-7 ;; BeeVisitGradient
  let numLand word "_Landscape" NumLandscapeFiles
  let numResource word "_NDVI" NumResourceFiles
  let numSeed word "_seed" RandomSeed
  let numBeeSize ( word "_" BeeSize "mm" )
  let x EdgeSize
  set x ( ( ( x + 1 ) * 10 ) ) / 1000
  let numEdgeSize ( word "_" x "km" )
  carefully
  [ file-delete ( word "BeeVisitGradient" numLand numResource numSeed numBeeSize numEdgeSize ".tiff" ) ]
  [ ]
  export-view ( word "BeeVisitGradient" numLand numResource numSeed numBeeSize numEdgeSize ".tiff" )
end
to snapshot
  ;; export-interface user-new-file
  let numLand word "_Landscape" NumLandscapeFiles
  let numResource word "_NDVI" NumResourceFiles
  let numSeed word "_seed" RandomSeed
  let numBeeSize ( word "_" BeeSize "mm" )
  let x EdgeSize
  set x ( ( ( x + 1 ) * 10 ) ) / 1000
  let numEdgeSize ( word "_" x "km" )
  carefully
  [ file-delete ( word "World_BEEFOR" numLand numResource numSeed numBeeSize numEdgeSize ".tiff" ) ]
  [ ]
  export-view ( word "World_BEEFOR" numLand numResource numSeed numBeeSize numEdgeSize ".tiff" )
end
;; ===========================================================================
;;;;; RECORD MOVIE FROM THE WORLD ;;;;
;; ATTENTION: This model's recording is frame rate sensitive, so consider recording each existing frame twice or consider using a post-processing tool (such as gstreamer or ffmpeg) to adjust the video playback speed
;; reference: http://ccl.northwestern.edu/netlogo/6.0.4/docs/transition.html
to start-recorder
  carefully [ vid:start-recorder ] [ user-message error-message ]
end
to reset-recorder
  let message (word
    "If you reset the recorder, the current recording will be lost"
    "Are you sure you want to reset the recorder?")
  if vid:recorder-status = "inactive" or user-yes-or-no? message
  [
    vid:reset-recorder
  ]
end
to save-recording
  if vid:recorder-status = "inactive"
  [
    user-message "The recorder is inactive. There is nothing to save"
    stop
  ]
  ; prompt user for movie location
  user-message ( word
    "Choose a name for your movie file (the "
    ".mp4 extension will be automatically added)" )
  let path2 user-new-file
  if not is-string? path2 [ stop ]  ; stop if user canceled
  ; export the movie
  carefully
  [
    vid:save-recording path2
    user-message ( word "Exported movie to " path2 )
  ]
  [
    user-message error-message
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
790
43
1798
1052
-1
-1
1.0
1
10
1
1
1
0
0
0
1
0
999
-999
0
0
0
1
ticks
30.0
BUTTON
17
44
188
98
Setup
if LoadSaveDirectoryFolder = 0 and outputData-1? = true and Choose-OutputData-1 = \"Sum\"\n[ \n set LoadSaveDirectoryFolder 0\n  user-message \"Choose the directory to load and save the files\" ;; assumes the user will choose a directory\n  set-current-directory user-directory   \n  set LoadSaveDirectoryFolder 1 \n]\n\nif LoadSaveDirectoryFolder = 0 and outputData-1? = true and Choose-OutputData-1 = \"Average\"\n[ \n set LoadSaveDirectoryFolder 0\n  user-message \"Choose the directory to load and save the files\" ;; assumes the user will choose a directory\n  set-current-directory user-directory   \n  set LoadSaveDirectoryFolder 1 \n]\n\n\nif LoadSaveDirectoryFolder = 0 and outputData-1? = true and Choose-OutputData-1 = \"Accumulated resource-i\"\n[ \n set LoadSaveDirectoryFolder 0\n  user-message \"Choose the directory to load and save the files\" ;; assumes the user will choose a directory\n  set-current-directory user-directory   \n  set LoadSaveDirectoryFolder 1 \n]\n\n\nif LoadSaveDirectoryFolder = 0 and outputData-1? = true and Choose-OutputData-1 = \"Sum and accumulated resource-i\"\n[ \n set LoadSaveDirectoryFolder 0\n  user-message \"Choose the directory to load and save the files\" ;; assumes the user will choose a directory\n  set-current-directory user-directory   \n  set LoadSaveDirectoryFolder 1 \n]\n\nif LoadSaveDirectoryFolder = 0 and outputData-2? = true \n[ \n set LoadSaveDirectoryFolder 0\n  user-message \"Choose the directory to load and save the files\" ;; assumes the user will choose a directory\n  set-current-directory user-directory   \n  set LoadSaveDirectoryFolder 1 \n]\n\nif LoadSaveDirectoryFolder = 0 and outputData-3? = true \n[ \n set LoadSaveDirectoryFolder 0\n  user-message \"Choose the directory to load and save the files\" ;; assumes the user will choose a directory\n  set-current-directory user-directory   \n  set LoadSaveDirectoryFolder 1 \n]\n\nif LoadSaveDirectoryFolder = 0 and outputData-4? = true\n[ \n set LoadSaveDirectoryFolder 0\n  user-message \"Choose the directory to load and save the files\" ;; assumes the user will choose a directory\n  set-current-directory user-directory   \n  set LoadSaveDirectoryFolder 1 \n]\n\nif LoadSaveDirectoryFolder = 0 and outputData-5? = true\n[ \n set LoadSaveDirectoryFolder 0\n  user-message \"Choose the directory to save the files\" ;; assumes the user will choose a directory\n  set-current-directory user-directory   \n  set LoadSaveDirectoryFolder 1 \n]\n\nif LoadSaveDirectoryFolder = 0 and outputData-6? = true\n[ \n set LoadSaveDirectoryFolder 0\n  user-message \"Choose the directory to save the files\" ;; assumes the user will choose a directory\n  set-current-directory user-directory   \n  set LoadSaveDirectoryFolder 1 \n]\n\n\nif LoadSaveDirectoryFolder = 0 and ExportViewBeeVisitGradient? = true\n  [\n    set LoadSaveDirectoryFolder 0\n    user-message \"Choose the directory to load and save the files\" ;; assumes the user will choose a directory\n    set-current-directory user-directory\n    set LoadSaveDirectoryFolder 1\n  ]\n\nsetup ;; CALL A PROCEDURE   
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
187
44
358
98
Go
go ;; CALL A PROCEDURE   \n\n\n\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0
INPUTBOX
18
227
117
287
Repetitions
10.0
1
0
Number
INPUTBOX
116
227
238
287
num-ResourceFiles
2.0
1
0
Number
INPUTBOX
237
227
359
287
num-LandscapeFiles
27.0
1
0
Number
INPUTBOX
18
298
117
358
num-ForageBees
1.0
1
0
Number
INPUTBOX
116
329
223
389
BeeCargoCapacity
1892.0
1
0
Number
INPUTBOX
222
329
359
389
BeeMetabolism
1.2
1
0
Number
SLIDER
116
298
359
331
BeeSize
BeeSize
1
10
2.0
1
1
mm
HORIZONTAL
BUTTON
18
356
117
389
Properties: bee
inspect bee 0
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
MONITOR
18
389
359
434
Total of num-ForageBees
count bees
17
1
11
TEXTBOX
20
10
300
34
Setup world and run the model:
19
0.0
1
SWITCH
547
541
768
574
ExportViewBeeVisitGradient?
ExportViewBeeVisitGradient?
1
1
-1000
SWITCH
547
584
768
617
outputData-2?
outputData-2?
1
1
-1000
SWITCH
319
541
441
574
outputData-1?
outputData-1?
0
1
-1000
SWITCH
320
687
441
720
outputData-3?
outputData-3?
1
1
-1000
SWITCH
547
687
669
720
outputData-4?
outputData-4?
1
1
-1000
SWITCH
320
791
541
824
outputData-5?
outputData-5?
1
1
-1000
SWITCH
547
791
669
824
outputData-6?
outputData-6?
1
1
-1000
SWITCH
440
541
540
574
Integer-1?
Integer-1?
0
1
-1000
INPUTBOX
547
616
768
676
NameOutfile-outputData-2
PatchVisitAbsoluteFrequency
1
0
String
INPUTBOX
319
616
540
676
NameOutfile-outputData-1
AccumulateResource
1
0
String
INPUTBOX
320
719
541
779
NameOutfile-outputData-3
BeeDistanceTraveled
1
0
String
INPUTBOX
547
719
768
779
NameOutfile-outputData-4
BeePath
1
0
String
INPUTBOX
320
823
541
883
NameOutfile-outputData-5
VisitantBees
1
0
String
INPUTBOX
547
823
768
883
NameOutfile-outputData-6
ProportionTraveledLandscape
1
0
String
CHOOSER
319
573
540
618
Choose-outputData-1
Choose-outputData-1
"Sum" "Average" "Accumulated resource-i" "Sum and accumulated resource-i"
0
SWITCH
440
687
541
720
Integer-3?
Integer-3?
1
1
-1000
SWITCH
668
687
768
720
Integer-4?
Integer-4?
1
1
-1000
SWITCH
668
791
768
824
Integer-6?
Integer-6?
1
1
-1000
TEXTBOX
321
511
508
537
Create outfiles:
19
0.0
1
SWITCH
18
541
304
574
ProbBeeChangeDirection?
ProbBeeChangeDirection?
0
1
-1000
CHOOSER
19
620
304
665
TypeWalk
TypeWalk
"Levy walk" "Simple" "Correlated directions" "Normally distributed step length 1" "Normally distributed step length 2" "Normally distributed step length 3" "Exponentially distributed step length" "Cauchy distributed step length"
5
SWITCH
20
754
304
787
FixTurningAngle?
FixTurningAngle?
1
1
-1000
INPUTBOX
20
786
304
851
FixRightTurn
0.2
1
0
Number
SLIDER
20
850
304
883
MeanStepLength
MeanStepLength
0.1
5
2.0
0.1
1
NIL
HORIZONTAL
SLIDER
167
690
304
723
StdevAngle
StdevAngle
0
90
90.0
1
1
NIL
HORIZONTAL
SWITCH
20
722
304
755
RandomWalk?
RandomWalk?
1
1
-1000
SWITCH
20
690
168
723
CorrelatedDirection?
CorrelatedDirection?
1
1
-1000
TEXTBOX
21
673
270
691
(some \"TypeWalk\" requires parameters below)
9
0.0
1
TEXTBOX
20
511
170
531
Bee movement:
16
0.0
1
SWITCH
790
10
1798
43
Display?
Display?
1
1
-1000
BUTTON
381
42
576
75
Floral resources
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [         \n      ;; low values of resources\n      ifelse resource-value <= 30 [ set pcolor gray ]  [\n        set pcolor green - 4 ] ;; high values of resource        \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]\n     
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
575
42
769
75
Floral resources labels
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      ifelse plabel = \"\" [\n        set plabel resource-value\n        set plabel-color white  \n      ] \n      [ \n        set plabel \"\"\n      ]\n    ]    \n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]\n\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
381
74
769
107
High values of resource
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [      \n      ;; low values of resource \n        ifelse resource-value  <= 30 [ set pcolor white ]  [\n        set pcolor green - 4 ] ;; high values of resource        \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]  
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
381
106
769
139
Low values of resource
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      ;; low values of resource\n      ifelse resource-value  <= 30 [ set pcolor gray ]  [\n        set pcolor white ] ;; high values of resource      \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]    
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
382
324
577
357
Bees
ask bees\n[\n ifelse hidden? = true\n [ show-turtle ]\n [ hide-turtle ]\n set label \"\"\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
576
324
771
357
Bee labels
ask bees [\n  ifelse label = \"\" [\n    show-turtle\n    set label  ( who )\n    set label-color white\n  ] \n  [ \n    ;hide-turtle\n    set label \"\"\n  ]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
382
368
771
401
Snapshot
snapshot\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
TEXTBOX
382
10
531
43
Display:
19
0.0
1
INPUTBOX
18
110
117
170
EdgeSize
999.0
1
0
Number
INPUTBOX
116
110
237
170
GrainSize-m
10.0
1
0
Number
INPUTBOX
236
110
359
170
ViewPatchSize
1.0
1
0
Number
MONITOR
18
169
359
214
World area in m2:
( EdgeSize + 1 ) * GrainSize-m * ( EdgeSize + 1 ) * GrainSize-m\n\n;;below in km2:\n;(( EdgeSize + 1 ) * GrainSize-m * ( EdgeSize + 1 ) * GrainSize-m ) / 1000000\n\n;;below world size (total of patches in the world ):\n;;( EdgeSize + 1 ) * ( EdgeSize + 1 )
17
1
11
SWITCH
18
445
190
478
CommunicationMode?
CommunicationMode?
1
1
-1000
SLIDER
189
445
359
478
Numbers
Numbers
1
2000
20.0
1
1
NIL
HORIZONTAL
BUTTON
381
152
576
185
Landcover
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      (\n        ifelse      \n        habitatcover = 1 [ set pcolor orange + 2.9 ] ;; crop rotation: functional patches\n        habitatcover = 2 [ set pcolor orange - 2 ] ;; perennial crop: functional patches\n        habitatcover = 3 [ set pcolor green + 1 ] ;; native grassland: functional patches\n        habitatcover = 4 [ set pcolor green - 1 ] ;; native shrubland: functional patches\n        habitatcover = 5 [ set pcolor green - 2.5 ] ;; native forest: functional patches\n        habitatcover = 6 [ set pcolor brown ] ;; environments that were regenerating, bare soil and roadsides: functional patches\n        habitatcover = 7 [ set pcolor blue ] ;; without resource (water / shadow): non-functional patches\n      )       \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]  \n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
575
152
770
185
Landcover labels
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [                 \n      ifelse plabel = \"\" [\n        set plabel habitatcover\n        set plabel-color white  \n      ] \n      [ \n        set plabel \"\"\n      ]        \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
381
184
576
217
Crop rotation
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      (\n        ifelse      \n        habitatcover = 1 [ set pcolor orange + 2.9 ] ;; crop rotation: functional patches\n        habitatcover = 2 [ set pcolor white ] ;; perennial crop: functional patches\n        habitatcover = 3 [ set pcolor white ] ;; native grassland: functional patches\n        habitatcover = 4 [ set pcolor white ] ;; native shrubland: functional patches\n        habitatcover = 5 [ set pcolor white ] ;; native forest: functional patches\n        habitatcover = 6 [ set pcolor white ] ;; environments that were regenerating, bare soil and roadsides: functional patches\n        habitatcover = 7 [ set pcolor white ] ;; without resource (water / shadow): non-functional patches\n      )       \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]  \n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
575
184
770
217
Perennial crop
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      (\n        ifelse      \n        habitatcover = 1 [ set pcolor white ] ;; crop rotation: functional patches\n        habitatcover = 2 [ set pcolor orange - 2 ] ;; perennial crop: functional patches\n        habitatcover = 3 [ set pcolor white ] ;; native grassland: functional patches\n        habitatcover = 4 [ set pcolor white] ;; native shrubland: functional patches\n        habitatcover = 5 [ set pcolor white ] ;; native forest: functional patches\n        habitatcover = 6 [ set pcolor white ] ;; environments that were regenerating, bare soil and roadsides: functional patches\n        habitatcover = 7 [ set pcolor white ] ;; without resource (water / shadow): non-functional patches\n      )       \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]  \n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
381
216
576
249
Native grassland
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      (\n        ifelse      \n        habitatcover = 1 [ set pcolor white] ;; crop rotation: functional patches\n        habitatcover = 2 [ set pcolor white ] ;; Perennial crop: functional patches\n        habitatcover = 3 [ set pcolor green + 1 ] ;; native grassland: functional patches\n        habitatcover = 4 [ set pcolor white] ;; native shrubland: functional patches\n        habitatcover = 5 [ set pcolor white ] ;; native forest: functional patches\n        habitatcover = 6 [ set pcolor white ] ;; environments that were regenerating, bare soil and roadsides: functional patches\n        habitatcover = 7 [ set pcolor white ] ;; without resource (water / shadow): non-functional patches\n      )       \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]  \n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
575
216
770
249
Native shrubland
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      (\n        ifelse      \n        habitatcover = 1 [ set pcolor white ] ;; rotary agriculture: functional patches\n        habitatcover = 2 [ set pcolor white ] ;; agriculture forest: functional patches\n        habitatcover = 3 [ set pcolor white ] ;; native grassland: functional patches\n        habitatcover = 4 [ set pcolor green - 1 ] ;; native shrubland: functional patches\n        habitatcover = 5 [ set pcolor white ] ;; native forest: functional patches\n        habitatcover = 6 [ set pcolor white ] ;; environments that were regenerating, bare soil and roadsides: functional patches\n        habitatcover = 7 [ set pcolor white ] ;; without resource (water / shadow): non-functional patches  \n      )       \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]  \n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
381
248
576
281
Native forest
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      (\n        ifelse      \n        habitatcover = 1 [ set pcolor white ] ;; crop rotation: functional patches\n        habitatcover = 2 [ set pcolor white ] ;;perennial crop: functional patches\n        habitatcover = 3 [ set pcolor white ] ;; native grassland: functional patches\n        habitatcover = 4 [ set pcolor white ] ;; native shrubland: functional patches\n        habitatcover = 5 [ set pcolor green - 2.5 ] ;; native forest: functional patches \n        habitatcover = 6 [ set pcolor white ] ;; environments that were regenerating, bare soil and roadsides: functional patches\n        habitatcover = 7 [ set pcolor white ] ;; without resource (water / shadow): non-functional patches  \n      )       \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]  \n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
575
248
770
281
Anthropized vegetation
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      (\n        ifelse      \n        habitatcover = 1 [ set pcolor white ] ;; rotary agriculture: functional patches\n        habitatcover = 2 [ set pcolor white ] ;; agriculture forest: functional patches\n        habitatcover = 3 [ set pcolor white ] ;; native grassland: functional patches\n        habitatcover = 4 [ set pcolor white ] ;; native shrubland: functional patches\n        habitatcover = 5 [ set pcolor white ] ;; native forest: functional patches\n        habitatcover = 6 [ set pcolor brown ] ;; environments that were regenerating, bare soil and roadsides: functional patches\n        habitatcover = 7 [ set pcolor white ] ;; without resource (water / shadow): non-functional patches       \n      )       \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n] 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
381
280
576
313
Without resource
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [\n      (\n        ifelse      \n        habitatcover = 1 [ set pcolor white ] ;; rotary agriculture: functional patches\n        habitatcover = 2 [ set pcolor white ] ;; agriculture forest: functional patches\n        habitatcover = 3 [ set pcolor white ] ;; native grassland: functional patches\n        habitatcover = 4 [ set pcolor white ] ;; native shrubland: functional patches\n        habitatcover = 5 [ set pcolor white ] ;; native forest: functional patches\n        habitatcover = 6 [ set pcolor white ] ;; environments that were regenerating, bare soil and roadsides: functional patches\n        habitatcover = 7 [ set pcolor blue ] ;; without resource (water / shadow): non-functional patches       \n      )       \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n] 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
575
280
770
313
Patch coordinate labels
let coord-X min-pxcor\nlet coord-Y max-pycor\nwhile [ coord-Y >= min-pycor ] [\n  while [ coord-X <= max-pxcor ] [\n    ask patch coord-X coord-Y [        \n      ifelse plabel = \"\" [\n        set plabel  ( word \" ( \" pxcor \",\" pycor \" )\" )\n        set plabel-color white\n      ] \n      [ \n        set plabel \"\"\n      ]       \n    ]\n    set coord-X coord-X + 1\n  ]\n  set coord-Y coord-Y - 1\n  set coord-X min-pxcor\n]\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
579
425
674
458
Start recorder
start-recorder
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
673
425
771
458
Reset recorder
reset-recorder
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
BUTTON
579
457
771
490
Save recording
save-recording
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1
MONITOR
382
445
580
490
NIL
vid:recorder-status
17
1
11
TEXTBOX
383
417
577
463
Create model movie:
19
0.0
1
TEXTBOX
455
519
605
537
(requires \"Setup world\")
9
0.0
1
SLIDER
18
573
304
606
DirectionProbability
DirectionProbability
0
1
0.05
0.01
1
NIL
HORIZONTAL
TEXTBOX
456
20
606
38
(requires \"Setup world\")
9
0.0
1
@#$#@#$#@
## WHAT IS IT?
The general purpose of BEEFOR-ABM is: to model the effect of landscape heterogeneity on foraging movement and the resource-obtaining capacity of bees with different profiles (sizes and sociality). This model is designed to be generic and applicable to several species of pollinator bees, which are defined by some parameters (representing the characteristics required for foraging in the landscape) established in the model interface.
## RECOMMENDATIONS
The ODD protocol will be available in the RLdaSS et al., 2022 thesis of the Federal University of Bahia, Brazil.
We recommend that any publication based on the use of BEEFOR-ABM shall includes, in the Supplementary Material, the NetLogo file itself that was used and all input files. If you change these codes, we recommend documenting the changes in full detail and providing a revised description of the ODD model.
## CREDITS AND REFERENCES
If you mention this model or the NetLogo software in a publication, we ask that you include the citations below. For the model itself: RLdaSS et al., 2022: doctoral thesis from the Federal University of Bahia, Brazil, entitled: Effect of Landscape Heterogeneity on Bee Populations and Communities.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250
airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15
arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150
box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75
bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30
butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60
car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58
circle
false
0
Circle -7500403 true true 0 0 300
circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123
cylinder
false
0
Circle -7500403 true true 0 0 300
dot
false
0
Circle -7500403 true true 90 90 120
face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240
face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225
face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183
fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30
flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45
flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120
leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195
line
true
0
Line -7500403 true 150 0 150 300
line half
true
0
Line -7500403 true 150 0 150 150
mybee
true
4
Rectangle -1184463 true true 105 150 180 240
Polygon -1184463 true true 105 240 135 270 150 270 180 240
Rectangle -16777216 true false 105 165 180 180
Line -16777216 false 135 105 135 75
Line -16777216 false 150 105 150 75
Line -16777216 false 135 75 120 75
Line -16777216 false 165 75 150 75
Rectangle -16777216 true false 105 195 180 210
Rectangle -16777216 true false 105 225 180 240
Polygon -1184463 true true 120 105 165 105 180 135 165 165 120 165 105 135
Polygon -7500403 true false 75 135 105 135 120 165 105 195 75 195 60 165
Polygon -7500403 true false 180 135 210 135 225 165 210 195 180 195 165 165
pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120
person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90
sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83
square
false
0
Rectangle -7500403 true true 30 30 270 270
square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240
star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108
target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60
tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152
triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255
triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224
truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42
turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99
wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269
wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113
x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="BEEFOR-ABM_EXPERIMENT" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>outputData-1</final>
    <exitCondition>NumLandscapeFiles = num-LandscapeFiles AND NumResourceFiles = num-ResourceFiles AND count bees = 0</exitCondition>
    <enumeratedValueSet variable="NameOutfile-outputData-3">
      <value value="&quot;BeeDistanceTraveled&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Choose-outputData-1">
      <value value="&quot;Sum&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-ForageBees">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixRightTurn">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outputData-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NameOutfile-outputData-4">
      <value value="&quot;BeePath&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-LandscapeFiles">
      <value value="27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NameOutfile-outputData-5">
      <value value="&quot;VisitantBees&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outputData-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outputData-5?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BeeMetabolism">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Integer-6?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NameOutfile-outputData-6">
      <value value="&quot;ProportionTraveledLandscape&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Numbers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outputData-6?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="StdevAngle">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FixTurningAngle?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BeeCargoCapacity">
      <value value="1892"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NameOutfile-outputData-1">
      <value value="&quot;AccumulateResource&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NameOutfile-outputData-2">
      <value value="&quot;PatchVisitAbsoluteFrequency&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RandomWalk?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MeanStepLength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CorrelatedDirection?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Integer-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Integer-4?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outputData-4?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Repetitions">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BeeSize">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EdgeSize">
      <value value="999"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ViewPatchSize">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-ResourceFiles">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Integer-3?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outputData-3?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TypeWalk">
      <value value="&quot;Normally distributed step length 3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ProbBeeChangeDirection?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DirectionProbability">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GrainSize-m">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CommunicationMode?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ExportViewBeeVisitGradient?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Display?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@