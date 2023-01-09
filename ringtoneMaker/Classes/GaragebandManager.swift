import UIKit
import AVFoundation
import MobileCoreServices
import AVKit
import Photos
import MediaPlayer
import Foundation

public class GaragebandManager: NSObject {

    public func CreateBand(name: String, sourceUrl: URL, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        
        
        let bundlePath = Bundle.main.url(forResource: "Base", withExtension: "band")
        let bundlePathString = bundlePath!.path
        let destPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let fileManager = FileManager.default
        let fullDestPath = NSURL(fileURLWithPath: destPath).appendingPathComponent("Base.band")
        let finalfullDestPath = NSURL(fileURLWithPath: destPath).appendingPathComponent(name+".band")
        let fullDestPathString = fullDestPath!.path
        let finalfullDestPathString = finalfullDestPath!.path

        do{
            try fileManager.copyItem(atPath: bundlePathString, toPath: fullDestPathString)
            try fileManager.copyItem(atPath: fullDestPathString, toPath: finalfullDestPathString)
        }catch{
            print("\n")
            print(error)
        }
        
        let myFilesPath = NSURL(fileURLWithPath: destPath).appendingPathComponent("/"+name+".band/Media/")
        let myDefaultAiff = NSURL(fileURLWithPath: destPath).appendingPathComponent("/"+name+".band/Media/ling 2.aiff")
        
        
        
        do{
            try fileManager.removeItem(at: myDefaultAiff!)
        }catch{
            print("\n")
            print(error)
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                        .userDomainMask,
                                                        true)
        let documentsDirectory = URL(string: paths.first!)
        let destUrl = documentsDirectory?.appendingPathComponent("/"+name+".band/Media/ling 2.aiff")
        
        
        convertAudio(sourceUrl, outputURL: destUrl!)
        
        do{
            try fileManager.removeItem(at: fullDestPath!)
        }catch{
            print("\n")
            print(error)
        }
        
        success(finalfullDestPath!)
    }
    
    func convertAudio(_ url: URL, outputURL: URL) {
        var error : OSStatus = noErr
        var destinationFile : ExtAudioFileRef? = nil
        var sourceFile : ExtAudioFileRef? = nil

        var srcFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()

        ExtAudioFileOpenURL(url as CFURL, &sourceFile)

        var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))

        ExtAudioFileGetProperty(sourceFile!,
            kExtAudioFileProperty_FileDataFormat,
            &thePropertySize, &srcFormat)

        dstFormat.mSampleRate = 44100  //Set sample rate
        dstFormat.mFormatID = kAudioFormatLinearPCM
        dstFormat.mChannelsPerFrame = 1
        dstFormat.mBitsPerChannel = 16
        dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mFramesPerPacket = 1
        dstFormat.mFormatFlags = kAudioFormatFlagIsBigEndian |
                                 kAudioFormatFlagIsSignedInteger

        // Create destination file
        error = ExtAudioFileCreateWithURL(
            outputURL as CFURL,
            kAudioFileAIFFType,
            &dstFormat,
            nil,
            AudioFileFlags.eraseFile.rawValue,
            &destinationFile)
        reportError(error: error)

        error = ExtAudioFileSetProperty(sourceFile!,
                kExtAudioFileProperty_ClientDataFormat,
                thePropertySize,
                &dstFormat)
        reportError(error: error)

        error = ExtAudioFileSetProperty(destinationFile!,
                                         kExtAudioFileProperty_ClientDataFormat,
                                        thePropertySize,
                                        &dstFormat)
        reportError(error: error)

        let bufferByteSize : UInt32 = 32768
        var srcBuffer = [UInt8](repeating: 0, count: 32768)
        var sourceFrameOffset : ULONG = 0

        while(true){
            var fillBufList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: 2,
                    mDataByteSize: UInt32(srcBuffer.count),
                    mData: &srcBuffer
                )
            )
            var numFrames : UInt32 = 0

            if(dstFormat.mBytesPerFrame > 0){
                numFrames = bufferByteSize / dstFormat.mBytesPerFrame
            }

            error = ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
            reportError(error: error)

            if(numFrames == 0){
                error = noErr;
                break;
            }

            sourceFrameOffset += numFrames
            error = ExtAudioFileWrite(destinationFile!, numFrames, &fillBufList)
            reportError(error: error)
        }

        error = ExtAudioFileDispose(destinationFile!)
        reportError(error: error)
        error = ExtAudioFileDispose(sourceFile!)
        reportError(error: error)
    }
    
    func reportError(error: OSStatus) {
        // Handle error
    }
    
    
}
