//
//  Sounds.swift
//
//  Created by Alfred Gao on 2017/1/6.
//
//

import Foundation
import AVFoundation

extension ResourcePackageReader {
    
    /// 音效
    ///
    /// sound effect
    /// - parameter withVibrate: 振动
    public func playSound(key: String, withVibrate: Bool = false) {
        // get volume config from other class
        
        var soundToPlay : SystemSoundID = 0
        if let _sid = sounds[key] {
            // reuse loaded sound
            soundToPlay = _sid
        } else {
            // loading sound data
            var _sdata: Data? = Data()
            
            if !_useprefix {
                _sdata = getData(key: key)
            } else {
                if let _value = getData(key: _keyprefix + key) {
                    _sdata = _value
                } else {
                    _sdata = getData(key: _keyprefixbackward + key)
                }
            }
            
            // register system sound
            if _sdata != nil {
                
                let _file = URL(fileURLWithPath: NSTemporaryDirectory().appending("sounds.\(UUID())"))
                do {
                    // write to temp file
                    try _sdata!.write(to: _file)
                    // reg sound
                    AudioServicesCreateSystemSoundID(_file as CFURL, &soundToPlay)
                    if soundToPlay != 0 {
                        sounds[key] = soundToPlay
                    }
                } catch {
                    // reg failed
                    return
                }
                // delete temp file
                do {
                    try FileManager.default.removeItem(at: _file)
                } catch {
                    
                }
            } else {
                // load sound data failed
                return
            }
        }

        if withVibrate {
            AudioServicesPlayAlertSound(soundToPlay)
        } else {
            AudioServicesPlaySystemSound(soundToPlay)
        }
    }
    
    /// 播放音乐
    ///
    /// play music
    func playMusic(_ key: String, loops: Int = 1, volume: Float = 100) {
        stopMusic()
        
        // load music data
        var _sdata: Data? = Data()
        if !_useprefix {
            _sdata = getData(key: key)
        } else {
            if let _value = getData(key: _keyprefix + key) {
                _sdata = _value
            } else {
                _sdata = getData(key: _keyprefixbackward + key)
            }
        }
        
        // play music
        if let _musicData = _sdata {
            do {
                musicPlayer = try AVAudioPlayer(data: _musicData)
                
                musicPlayer?.volume = volume
                musicPlayer?.numberOfLoops = loops
                musicPlayer?.play()
            } catch {
            }
        }
    }
    /// 停止音乐播放
    ///
    /// stop music
    func stopMusic() {
        musicPlayer?.stop()
    }
    
}
