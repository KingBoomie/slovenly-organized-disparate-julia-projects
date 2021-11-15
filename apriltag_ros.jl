# !! auto-generated code, do not edit !!
module apriltag_ros
using RobotOSData.Messages
using RobotOSData.StdMsgs
using RobotOSData.CommonMsgs
struct AprilTagDetection <: Readable
    id::Vector{Int32}
    size::Vector{Float64}
    pose::geometry_msgs.PoseWithCovarianceStamped
end
struct AprilTagDetectionArray <: Readable
    header::std_msgs.Header
    detections::Vector{AprilTagDetection}
end
end
