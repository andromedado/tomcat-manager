//
//  ProjectManager.swift
//  TomcatManager
//
//  Created by Shad Downey on 4/21/17.
//  Copyright © 2017 Shad Downey. All rights reserved.
//

import Foundation

fileprivate let kUpdateInterval : TimeInterval = 1.0

protocol ProjectManagerDelegate : WebAppManagerDelegate {
    //
}

class ProjectManager {

    unowned var delegate : ProjectManagerDelegate

    var webAppManager : WebAppManager

    fileprivate var updateTimer : Timer?

    init(delegate : ProjectManagerDelegate) {
        self.delegate = delegate

        self.webAppManager = WebAppManager()
        self.webAppManager.delegate = self.delegate
    }

    func setup() {
        self.webAppManager.scan()

        self.updateTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: kUpdateInterval, repeats: true) { [weak self] (timer) in
            guard let strongSelf = self else {
                timer.invalidate()
                return
            }
            strongSelf.update()
        }
        timer.tolerance = kUpdateInterval / 5
        self.updateTimer = timer
    }

    func updateMenuItems() {
        self.webAppManager.updateAppItems()
    }

    fileprivate func update() {
        self.webAppManager.update()
    }

}

