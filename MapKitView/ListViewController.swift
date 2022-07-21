//
//  ListViewController.swift
//  MapKitView
//
//  Created by Muhsin Can Yılmaz on 16.07.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var isimDizisi = [String]()
    var idDizisi = [UUID()]
    
    var secilenYerIsmı = ""
    var secilenYerId = UUID()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButton))
    
        verileriAl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(verileriAl), name: NSNotification.Name("notification"), object: nil)
        
    }
    
    @objc func verileriAl(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        
        do{
            let sonuclar = try context.fetch(request)
            
            isimDizisi.removeAll()
            idDizisi.removeAll()
            
            if sonuclar.count > 0 {
                for sonuc in sonuclar as! [NSManagedObject] {
                    if let isim = sonuc.value(forKey: "name") as? String{
                        isimDizisi.append(isim)
                    }
                    if let id = sonuc.value(forKey: "id") as? UUID{
                        idDizisi.append(id)
                    }
                    
                }
                tableView.reloadData()
            }
            
        }catch{
            
        }
        
    }
    
    @objc func addButton() {
        secilenYerIsmı = ""
        performSegue(withIdentifier: "toMapsVc", sender: nil)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        secilenYerIsmı = isimDizisi[indexPath.row]
        secilenYerId = idDizisi[indexPath.row]
        performSegue(withIdentifier: "toMapsVc", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVc" {
            let destination = segue.destination as! MapsViewController
            destination.secilenIsım = secilenYerIsmı
            destination.secilenId = secilenYerId
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
            
            let idString = idDizisi[indexPath.row].uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            do{
                let sonuclar = try context.fetch(fetchRequest)
                for sonuc in sonuclar as! [NSManagedObject]{
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        if id == idDizisi[indexPath.row]{
                            context.delete(sonuc)
                            idDizisi.remove(at: indexPath.row)
                            isimDizisi.remove(at: indexPath.row)
                            
                            tableView.reloadData()
                            
                            do{
                                try context.save()
                            }catch{
                                
                            }
                            break
                        }
                    }
                    
                }
                
            }catch{
                
            }
        }
    }
    
    
}
