//  ZestTableView
//
//  Created by Mohammad Zulqarnain on 09/06/2019.
//  Copyright © 2019 Mohammad Zulqarnain. All rights reserved.

import UIKit


class ZestTableView: UITableView {
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.accessibilityIdentifier = "ZestTableView"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

