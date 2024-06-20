breed [students student]

turtles-own [
  stage
  time-in-stage
  next-stage
  total-time
]

globals [
  stages
  stage-names
  total-times
  total-counts
  average-times
  move-threshold
  deviation
  total-students
]

to setup
  clear-all
  reset-ticks
  set stages (list
    patch -10 -16  ;; ENTRY
    patch -15 -8   ;; PAY
    patch -16 2    ;; B1
    patch -16 10   ;; B2
    patch -10 16   ;; B3
    patch -2 16    ;; B4
    patch 8 16     ;; B5
    patch 15 10    ;; B6
    patch 15 -2    ;; B7
    patch 15 -8    ;; EXIT
  )
  set stage-names ["ENTRY" "PAY" "B1" "B2" "B3" "B4" "B5" "B6" "B7" "EXIT"]
  set total-times n-values (length stages) [0]
  set total-counts n-values (length stages) [0]
  set average-times n-values (length stages) [0]
  set move-threshold 108
  set total-students 0
  ask patches [set pcolor 66]
  create-sector
  create-public initial-group-size
end

to create-sector
  foreach stages [
    stage-patch ->
    let stage-index position stage-patch stages
    ask stage-patch [
      set plabel item stage-index stage-names
    ]
  ]
end

to create-public [initial-size]
  create-students initial-size [
    set shape "person"
    setxy -11 -16
    set stage item 0 stages
    set time-in-stage 0
    set next-stage nobody
    set total-time 0
  ]
end

to go
  if not any? students [
    display-average-times
    calculate-standard-deviation
    stop
  ]
  move-students
  tick
  display-average-times
  possibly-create-new-students
end

to move-students
  ask students [
    let current-index position stage stages
    ifelse current-index = (length stages - 1) [
      set total-students total-students + 1
      die
    ] [
      set next-stage item (current-index + 1) stages
      if current-index < (length stages - 1) [
        update-stage-time current-index time-in-stage
      ]
      if count students-on next-stage = 0 and time-in-stage >= random-triangular 10 move-threshold 10.8 [
        move-to next-stage
        set stage next-stage
        set time-in-stage 0
        set total-time total-time + time-in-stage
      ] [
        set time-in-stage time-in-stage + 1
      ]
    ]
  ]
end

to possibly-create-new-students
  if random-float 1 < new-student-prob [
    create-public 1
  ]
end

to update-stage-time [index time]
  set total-times replace-item index total-times (item index total-times + time)
  set total-counts replace-item index total-counts (item index total-counts + 1)
end

to-report average-time [total-time-val total-count-val]
  ifelse total-count-val > 0 [
    report total-time-val / total-count-val
  ] [
    report 0
  ]
end

to display-average-times
  let temp-average-times []
  (foreach stage-names total-times total-counts [
    [stage-name total-time-val total-count-val] ->
      let avg-time average-time total-time-val total-count-val
      set temp-average-times lput avg-time temp-average-times
      show (word "Tempo medio em " stage-name ": " avg-time " (total time: " total-time-val ", total count: " total-count-val ")")
  ])
  set average-times temp-average-times
end

to calculate-standard-deviation
    let mean-time (sum [total-time] of students) / total-students
    let var-time (sum [(total-time - mean-time) ^ 2] of students) / total-students
    let std-dev sqrt var-time
    show (word "Desvio padrão do tempo para completar: " std-dev)
    set deviation std-dev
end

to-report random-triangular [min-val max-val mode]
  let u1 random-float 1
  let u2 random-float 1
  let f (mode - min-val) / (max-val - min-val)
  ifelse u1 <= f [
    report min-val + sqrt (u2 * (max-val - min-val) * (mode - min-val))
  ] [
    report max-val - sqrt ((1 - u2) * (max-val - min-val) * (max-val - mode))
  ]
end

to-report format-time [total-ticks]
  let seconds total-ticks mod 60
  let minutes (total-ticks / 60) mod 60
  let hours total-ticks / 3600
  report (word hours ":" minutes ":" seconds)
end
