module Bezier exposing
    ( BezierEasingFunc
    , BezierPointFunc
    , bezierBinEpsilon
    , bezierBinFixed
    , bezierBinHybrid
    , bezierPoint
    , bezierPointAdvancedOptimized
    , bezierPointAdvancedOriginal
    , bezierPointSimple
    )

-- EASINGS


type alias BezierEasingFunc =
    Float -> Float -> Float -> Float -> Float -> Float


{-| Binary search with a fixed number of steps
-}
bezierBinFixed : BezierEasingFunc
bezierBinFixed x1 y1 x2 y2 =
    let
        f =
            bezierPoint x1 y1 x2 y2
    in
    \time ->
        bezierBinFixedHelper fixedSteps f time ( 0, 1 )


fixedSteps : number
fixedSteps =
    8


bezierBinFixedHelper : Int -> (Float -> ( Float, Float )) -> Float -> ( Float, Float ) -> Float
bezierBinFixedHelper steps f t ( tMin, tMax ) =
    let
        tMid =
            (tMin + tMax) / 2

        ( x, y ) =
            f tMid
    in
    if steps == 0 then
        y

    else
        let
            newRange =
                if x < t then
                    ( tMid, tMax )

                else
                    ( tMin, tMid )
        in
        bezierBinFixedHelper (steps - 1) f t newRange


{-| Binary search with a fixed precision
-}
bezierBinEpsilon : BezierEasingFunc
bezierBinEpsilon x1 y1 x2 y2 =
    let
        func =
            bezierPoint x1 y1 x2 y2
    in
    \time ->
        bezierBinEpsilonHelper func time ( 0, 1 )


epsilon : Float
epsilon =
    0.00075


bezierBinEpsilonHelper f t ( tMin, tMax ) =
    let
        tMid =
            (tMin + tMax) / 2

        ( x, y ) =
            f tMid
    in
    if abs (t - x) < epsilon then
        y

    else
        let
            newRange =
                if x < t then
                    ( tMid, tMax )

                else
                    ( tMin, tMid )
        in
        bezierBinEpsilonHelper f t newRange


{-| A combination of bezierBinFixed and bezierBinEpsilon
-}
bezierBinHybrid : BezierEasingFunc
bezierBinHybrid x1 y1 x2 y2 =
    let
        f =
            bezierPoint x1 y1 x2 y2
    in
    \time ->
        bezierBinHybridHelper fixedSteps f time ( 0, 1 )


bezierBinHybridHelper : Int -> (Float -> ( Float, Float )) -> Float -> ( Float, Float ) -> Float
bezierBinHybridHelper steps f t ( tMin, tMax ) =
    let
        tMid =
            (tMin + tMax) / 2

        ( x, y ) =
            f tMid
    in
    if steps == 0 || abs (t - x) < epsilon then
        y

    else
        let
            newRange =
                if x < t then
                    ( tMid, tMax )

                else
                    ( tMin, tMid )
        in
        bezierBinHybridHelper (steps - 1) f t newRange



-- POINTS


type alias BezierPointFunc =
    Float -> Float -> Float -> Float -> Float -> ( Float, Float )


bezierPoint : BezierPointFunc
bezierPoint =
    bezierPointSimple


{-| Naive approach, reverse-engineered from the gifs at
<https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Higher-order_curves>
-}
bezierPointSimple : BezierPointFunc
bezierPointSimple x1 y1 x2 y2 time =
    let
        q0 =
            interpolate2d ( 0, 0 ) ( x1, y1 ) time

        q1 =
            interpolate2d ( x1, y1 ) ( x2, y2 ) time

        q2 =
            interpolate2d ( x2, y2 ) ( 1, 1 ) time

        r0 =
            interpolate2d q0 q1 time

        r1 =
            interpolate2d q1 q2 time

        b =
            interpolate2d r0 r1 time
    in
    b


{-| Return a point on line segment (a, b) for given t between (0,1)
-}
interpolate2d : ( Float, Float ) -> ( Float, Float ) -> Float -> ( Float, Float )
interpolate2d ( xa, ya ) ( xb, yb ) t =
    ( xa + t * (xb - xa)
    , ya + t * (yb - ya)
    )


{-| This is Easing.bezier from elm-community/timing-functions, modified to return (x, y) instead of y
-}
bezierPointAdvancedOriginal : BezierPointFunc
bezierPointAdvancedOriginal x1 y1 x2 y2 time =
    let
        lerp_ from to v =
            from + (to - from) * v

        pair_ interpolate ( a0, b0 ) ( a1, b1 ) v =
            ( interpolate a0 a1 v, interpolate b0 b1 v )

        casteljau_ ps =
            case ps of
                [ ( x, y ) ] ->
                    ( x, y )

                xs ->
                    List.map2 (\x y -> pair_ lerp_ x y time) xs (Maybe.withDefault [] (List.tail xs))
                        |> casteljau_
    in
    casteljau_ [ ( 0, 0 ), ( x1, y1 ), ( x2, y2 ), ( 1, 1 ) ]


{-| Easing.bezier again, this time without local functions
-}
bezierPointAdvancedOptimized : BezierPointFunc
bezierPointAdvancedOptimized x1 y1 x2 y2 =
    casteljau [ ( 0, 0 ), ( x1, y1 ), ( x2, y2 ), ( 1, 1 ) ]


lerp from to v =
    from + (to - from) * v


pair interpolate ( a0, b0 ) ( a1, b1 ) v =
    ( interpolate a0 a1 v, interpolate b0 b1 v )


casteljau ps t =
    case ps of
        [ ( x, y ) ] ->
            ( x, y )

        _ ->
            casteljau
                (List.map2 (\x y -> pair lerp x y t) ps (Maybe.withDefault [] (List.tail ps)))
                t
