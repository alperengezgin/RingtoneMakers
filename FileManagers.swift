

import Foundation
import AVFoundation

public class FileManagers {
    
    public var ringtones = [Ringtone]()
    
    init() {
        setupFileManager()
    }
    
    public func setupFileManager() {
        ringtones.removeAll()
        fetchSavedTones()
    }
    
    fileprivate func fetchSavedTones() {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var audioPaths: [URL] = []
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)
            
            audioPaths = directoryContents.filter{ $0.pathExtension == "mp3" ||  $0.pathExtension == "m4a" || $0.pathExtension == "aiff" || $0.pathExtension == "wav"}
            
            
            let fileNames = audioPaths.map{ $0.deletingPathExtension().lastPathComponent }
            let fileExtensions = audioPaths.map{$0.pathExtension}
            
            for i in 0..<audioPaths.count {
                let path = audioPaths[i]
                let name = fileNames[i]
                let ext = fileExtensions[i]
                let duration = calculateDuration(url: path)
                let size = path.fileSizeString
                
                let ringtone = Ringtone(fileExtension: ext, name: name, path: path, duration: duration, size: size)
                ringtones.append(ringtone)
            }
            
        } catch {
            
        }
        
        
    }
    
    fileprivate func calculateDuration(url: URL) -> Double {
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        var minute: Double
        var secondFirst: Double
        secondFirst = Double(duration).truncatingRemainder(dividingBy: 60.0)
        let second = secondFirst / 100
        minute = (duration - secondFirst) / 60.0
        let response = minute + second
        return Double(round(100*response)/100)
    }
    
    public func load(url: URL, localUrl: URL, completion: @escaping () -> (Void)) {
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = try! URLRequest(url: url)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }
                
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                    completion()
                } catch (let writeError) {
                    print("error writing file \(localUrl) : \(writeError)")
                }
                
            } else {
                print("Failure: %@", error?.localizedDescription);
            }
        }
        task.resume()
    }
    
    public func deleteFile(_ filePath:URL) {
            guard FileManager.default.fileExists(atPath: filePath.path) else {
                return
            }
            do {
                try FileManager.default.removeItem(atPath: filePath.path)
            }catch{
                fatalError("Unable to delete file: \(error) : \(#function).")
            }
        }
    
    func trimAudio(name: String, sourceURL: URL, startTime: Double, stopTime: Double, fin: Bool, fout: Bool, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        
            let asset = AVAsset(url: sourceURL)
            
            let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith:asset)
            
            if compatiblePresets.contains(AVAssetExportPresetMediumQuality) {
                
                
                let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                var outputURL = documentDirectory
                do {
                    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                    outputURL = outputURL.appendingPathComponent("\(name).aiff")
                }catch let error {
                    failure(error.localizedDescription)
                }
                
                
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: outputURL.path) {
                    outputURL = documentDirectory
                    do {
                        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                        outputURL = outputURL.appendingPathComponent("\(name) copy.aiff")
                    }catch let error {
                        print(error)
                    }
                } else {
                    print("FILE NOT AVAILABLE")
                }
                
                
                let durationInSeconds = stopTime
                let params = AVMutableAudioMixInputParameters(track: asset.tracks.first! as AVAssetTrack)
                let item = AVPlayerItem(asset: asset)
                if fin {
                    let firstSecond = CMTimeRangeMake(CMTimeMakeWithSeconds(0, 1), CMTimeMakeWithSeconds(2, 1))
                    params.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: firstSecond)
                }
                if fout{
                    let lastSecond = CMTimeRangeMake(CMTimeMakeWithSeconds(durationInSeconds-2, 1), CMTimeMakeWithSeconds(2, 1))
                    params.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: lastSecond)
                }
                
                let mix = AVMutableAudioMix()
                
                if fin && fout {
                    mix.inputParameters = [params]
                }
                else if fin && !fout {
                    mix.inputParameters = [params]
                }
                else if !fin && fout {
                    mix.inputParameters = [params]
                }
                
                
                guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else{return}
                exportSession.outputURL = outputURL
                exportSession.outputFileType = AVFileType.m4a
                if fin && fout {
                    exportSession.audioMix = mix
                }
                else if fin && !fout {
                    exportSession.audioMix = mix
                }
                else if !fin && fout {
                    exportSession.audioMix = mix
                }
                
                
                let range: CMTimeRange = CMTimeRangeFromTimeToTime(CMTimeMakeWithSeconds(startTime, asset.duration.timescale), CMTimeMakeWithSeconds(stopTime, asset.duration.timescale))
                exportSession.timeRange = range
                
                
                exportSession.exportAsynchronously(completionHandler: {
                    switch exportSession.status {
                    case .completed:
                        success(outputURL)
                        
                    case .failed:
                        if let _error = exportSession.error?.localizedDescription {
                            failure(_error)
                        }
                        
                    case .cancelled:
                        if let _error = exportSession.error?.localizedDescription {
                            failure(_error)
                        }
                        
                    default:
                        if let _error = exportSession.error?.localizedDescription {
                            failure(_error)
                        }
                    }
                })
            }
        }
}
