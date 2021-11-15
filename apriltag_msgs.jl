# !! auto-generated code, do not edit !!
module apriltag_msgs
using RobotOSData.Messages
$(Expr(:using, :($(Expr(:., :(RobotOSData.StdMsgs))))))
$(Expr(:using, :($(Expr(:., :(RobotOSData.CommonMsgs))))))
struct Point <: Readable
    x::Float64
    y::Float64
end
struct AprilTagDetection <: Readable
    family::String
    id::Int32
    hamming::Int32
    goodness::Float32
    decision_margin::Float32
    centre::Point
    corners::SVector{4, Point}
    homography::SVector{9, Float64}
end
struct AprilTagDetectionArray <: Readable
    header::std_msgs.Header
    detections::Vector{AprilTagDetection}
end
end
