//
//  SearchBar.swift
//  CryptoTracker
//
//  Created by Константин Клинов on 30/06/25.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search cryptocurrencies...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
