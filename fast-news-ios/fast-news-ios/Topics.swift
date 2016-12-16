//
//  Topics.swift
//  fast-news-ios
//
//  Created by Nate Parrott on 12/15/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import Foundation

struct Topic {
    let type: TopicType
    let text: String
    
}

enum TopicType {
    case Person
    case Organization
    case Place
    
    static func fromLinguisticTag(type: String) -> TopicType? {
        switch type {
        case NSLinguisticTagPlaceName: return TopicType.Place
        case NSLinguisticTagPersonalName: return TopicType.Organization
        case NSLinguisticTagPersonalName: return TopicType.Person
        default: return nil
        }
    }
}

extension Article {
    func _computeTopics() -> [Topic] {
        var topics = [Topic]()
        
        let taggerOptions: NSLinguisticTaggerOptions = .JoinNames
        let tagger: NSLinguisticTagger = NSLinguisticTagger(tagSchemes: [NSLinguisticTagSchemeNameType], options: Int(taggerOptions.rawValue))
        
        let text: NSString = (title ?? "") + "\n" + (articleDescription ?? "")
        tagger.string = text as String
        tagger.enumerateTagsInRange(NSRange(location: 0, length: text.length), scheme: NSLinguisticTagSchemeNameType, options: [], usingBlock: { (let tag, let tokenRange, let sentenceRange, _) in
            let token = text.substringWithRange(tokenRange)
            if let type = TopicType.fromLinguisticTag(tag) {
                topics.append(Topic(type: type, text: token))
            }
        })
        return topics
    }
}
