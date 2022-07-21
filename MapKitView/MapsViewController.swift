//
//  ViewController.swift
//  MapKitView
//
//  Created by Muhsin Can Yılmaz on 16.07.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController , MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var kaydetButtonOutlet: UIButton!
    @IBOutlet weak var yorumTextField: UITextField!
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsım = ""
    var secilenId = UUID()
    
    var annotationTitle = String()
    var annotationSubtitle  = String()
    var annotationLatitude = Double()
    var annotationLongtitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(uzunTiklandı(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if secilenIsım != ""{
            kaydetButtonOutlet.isHidden = true
            //coredata verileri getir
            let idString = secilenId.uuidString
            
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let sonuclar = try context.fetch(fetchRequest)
                if sonuclar.count > 0 {
                    for sonuc in sonuclar as! [NSManagedObject] {
                        
                        if let isim = sonuc.value(forKey: "name") as? String {
                            
                            if let comment = sonuc.value(forKey: "comment") as? String {
                                
                                if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                    
                                    if let longtitude = sonuc.value(forKey: "longitude") as? Double {
                                        
                                        annotationTitle = isim
                                        annotationSubtitle = comment
                                        annotationLatitude = latitude
                                        annotationLongtitude = longtitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongtitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        
                                        isimTextField.text = annotationTitle
                                        yorumTextField.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        let coordinateRegion = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongtitude)
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinateRegion, span: span)
                                        
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }catch{
                
            }
            
        }else{
            
            //yeni kayıt oluştur
            
            isimTextField.text = ""
            yorumTextField.text = ""
            
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let reuseId = "SabitId"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId) //  Pin olması önemli :D
            pinView?.canShowCallout = true
            pinView?.tintColor = .blue
            
            let button = UIButton(type: .infoLight)
            pinView?.rightCalloutAccessoryView = button
            
            
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    @objc func uzunTiklandı (gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            
            secilenLatitude = dokunulanKordinat.latitude
            secilenLongitude = dokunulanKordinat.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKordinat
            annotation.title = isimTextField.text
            annotation.subtitle = yorumTextField.text
            mapView.addAnnotation(annotation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print(locations[0].coordinate.latitude)
        //print(locations[0].coordinate.longitude)
        if secilenIsım == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: false)
        }
       
    }
    @IBAction func kaydetButton(_ sender: Any) {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Place", into: context)
        
        yeniYer.setValue(isimTextField.text, forKey: "name")
        yeniYer.setValue(yorumTextField.text, forKey: "comment")
        yeniYer.setValue(UUID(), forKey: "id")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        
        do{
            try context.save()
            print("kayıt edildi")
        }catch{
            
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("notification"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsım != ""{
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongtitude)  //secilenLatitude olmuyor Dikkat
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placeMarkDizisi, hata in
                if let placeMarks = placeMarkDizisi{
                    if placeMarks.count > 0 {
                       
                        let yeniPlaceMark = MKPlacemark(placemark: placeMarks[0])  //MKPlacemark Dikkat :D
                        let item = MKMapItem(placemark: yeniPlaceMark)
                        
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
        }
    }
    
}

