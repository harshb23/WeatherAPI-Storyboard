//
//  HistoryViewController.swift
//  Lab03
//
//  Created by Harsh Bhatt on 2023-04-21.
//

import UIKit
import CoreData

class HistoryViewController: UIViewController {
    
    
    @IBOutlet weak var historyTable: UITableView!
    
    private var items: [HistoryItem] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()

        loadItems()
        historyTable.dataSource = self
        historyTable.delegate = self
    }
    
    private func saveItems() {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    private func loadItems() {
        guard let context = getCoreContext() else {
            return
        }
        
        let request = HistoryItem.fetchRequest()
        
        do {
            try items = context.fetch(request)
            
            self.historyTable.reloadData()
        } catch {
            print(error)
        }
    }
    
    private func getCoreContext() -> NSManagedObjectContext? {
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    }
    

    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        //removeHistory()
    }
    
    private func removeHistory(indexPath: IndexPath) {
        
        let alertViewController = UIAlertController(title: "Delete", message: "Are you sure you want to delete the History ?", preferredStyle: .alert)
        
        alertViewController.addAction(UIAlertAction(title: "No", style: .cancel))
        alertViewController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            
            self.getCoreContext()?.delete(self.items[indexPath.row])
           
//            self.getCoreContext()?.delete(self.items[])
//            self.saveItems()
//
//            self.items.remove()
            
            self.historyTable.reloadData()
        }))
        
        self.present(alertViewController, animated: true)
        
    }

}

extension HistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell" , for: indexPath)
        let item = items[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        if let code = item.errorCode {
            content.text =  "Code: \(code)"
        }
        content.secondaryText = item.errorMessage
        
        if let icon = item.iconName {
            content.image = UIImage(systemName: icon)
        } else {
            content.image = UIImage(systemName: "cloud")
        }
        
        cell.contentConfiguration = content
        
        return cell
    }
}

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        removeItem(at: indexPath)
    }
    
    private func removeItem(at indexPath: IndexPath) {
        
        let alertViewController = UIAlertController(title: "Complete ?", message: "Are you sure you want to remove ?", preferredStyle: .alert)
        
        alertViewController.addAction(UIAlertAction(title: "No", style: .cancel))
        alertViewController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            
            self.getCoreContext()?.delete(self.items[indexPath.row])
            
            self.saveItems()
            
            self.items.remove(at: indexPath.row)
            
            self.historyTable.reloadData()
        }))
        
        self.present(alertViewController, animated: true)
        
    }
}
