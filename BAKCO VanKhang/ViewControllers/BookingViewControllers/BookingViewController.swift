//
//  BookingViewController.swift
//  BAKCO VanKhang
//
//  Created by Kiet on 5/3/18.
//  Copyright © 2018 Lou. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD
import Alamofire
import IQDropDownTextField
import AlamofireSwiftyJSON
import DropDown
import SwiftyJSON
import Presentr


/// MARK: PROPERTIES.
class BookingViewController: BaseViewController {
    
    var didUseInsurance: (Bool) -> Void = { result in
        BookingInfo.didUseHI = result
    }
    
    var exTypeDropdown = DropDown()
    var hiDropdown = DropDown()
    
    //Presntr.
    var presentr : Presentr = {
        let width = ModalSize.custom(size: Float(UIScreen.main.bounds.size.width) - 30.0)
        let height = ModalSize.fluid(percentage: 0.9)
        let center = ModalCenterPosition.center
        let customType = PresentationType.custom(width: width, height: height, center: center)
        
        let customPresenter = Presentr(presentationType: customType)
        customPresenter.transitionType = .coverVertical
        customPresenter.dismissTransitionType = .coverVertical
        customPresenter.roundCorners =  true
        customPresenter.backgroundColor = UIColor.darkGray
        customPresenter.backgroundOpacity = 0.3
        customPresenter.dismissOnSwipe = true
        customPresenter.dismissOnSwipeDirection = .bottom
        customPresenter.keyboardTranslationType = .stickToTop
        return customPresenter
    }()
    
    @IBOutlet var paintentTextfield: UITextField!
    @IBOutlet var hospitalTextfield: UITextField!
    @IBOutlet var hIIdTextfield: UITextField!
    @IBOutlet var exTypeTextfield: UITextField!
    @IBOutlet var expDocOrSpecialtyTextfield: UITextField!
    @IBOutlet var dateAndTimeTextfield: UITextField!
    @IBOutlet var ExpDocOrSpecialtyLabel: UILabel!
    
    @IBAction func showHospitals(_ sender: Any) {
        let hospitalVc = MyStoryboard.bookingStoryboard.instantiateViewController(withIdentifier: "HospitalViewController") as! HospitalViewController
        hospitalVc.delegate = self
        let nav = BaseNavigationController(rootViewController: hospitalVc)
        present(nav, animated: true)
    }
    
    @IBAction func showExpertDoctor(_ sender: Any) {
        guard let hosName = hospitalTextfield.text,
            let exType = exTypeTextfield.text else { return }
        if hosName == "" {
            showAlert(title: "Lỗi", mess: "Bạn chưa chọn bệnh viện", style: .alert)
        } else if exType == "" {
            showAlert(title: "Lỗi", mess: "Bạn chưa chọn loại hình khám", style: .alert)
        }  else {
            if exType == Expert {
                showExpDoc()
            } else {
                showSpecialty()
            }
        }
    }
    
    @IBAction func showScheduler(_ sender: Any) {
        if paintentTextfield.text == "" {
            showAlert(title: "Lỗi", mess: "Bạn chưa chọn bệnh viện", style: .alert)
        } else if hospitalTextfield.text == "" {
            
        } else if exTypeTextfield.text == "" {
            showAlert(title: "Lỗi", mess: "Bạn chưa chọn loại hình khám", style: .alert)
        } else if expDocOrSpecialtyTextfield.text == "" {
            if BookingInfo.exTypeId == Constant.exTypeDict[Expert] {
                showAlert(title: "Lỗi", mess: "Bạn chưa chọn chuyên gia", style: .alert)
            } else {
                showAlert(title: "Lỗi", mess: "Bạn chưa chọn chuyên khoa", style: .alert)
            }
        } else {
            let vc = MyStoryboard.bookingStoryboard.instantiateViewController(withIdentifier: "SchedulersViewController") as! SchedulersViewController
            vc.delegate = self
            let nav = BaseNavigationController(rootViewController: vc)
            present(nav, animated: true)
        }
        
    }
    
    @IBAction func confirm(_ sender: Any) {
        if validate() {
            showAlert(title: "Xác nhận", message: "Bạn có chắc muốn đăng kí nhận phiếu hẹn khám chữa bệnh? \n(Sau khi đặt cuộc hẹn, bệnh nhân không thể sửa hoặc huỷ).", style: .alert) { (_) in
                if BookingInfo.exTypeId == Constant.exTypeDict[Expert] {
                    // for expert
                    self.createExaminationNoteWithDoctor()
                } else {
                    // for normal
                    self.createExamninationNote()
                }
            }
        }
    }
    
    @IBAction func userDropdown(_ sender: Any) {
        let vc = MyStoryboard.bookingStoryboard.instantiateViewController(withIdentifier: "PaintentListViewController") as! PaintentListViewController
        vc.direct = .booking
        let nav = BaseNavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    @IBAction func hiDropdown(_ sender: Any) {
        guard let paintentName = paintentTextfield.text else { return }
        if paintentName == "" || BookingInfo.paintent.id == 0 {
            showAlert(title: "Lỗi", mess: "Bạn chưa chọn bệnh nhân!", style: .alert)
        } else {
            self.hiDropdown.show()
        }
    }
    
    @IBAction func examinationTypesDropdown(_ sender: Any) {
        if hospitalTextfield.text != "" {
            self.exTypeDropdown.show()
        } else {
            self.showAlert(title: "Lỗi", mess: "Chưa chọn bệnh viện", style: .alert)
        }
    }
    
    override func popToBack() {
        navigationController?.popViewController(animated: true)
        BookingInfo.release()
    }
}


// Mark: FUNCTIONS.
extension BookingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BookingInfo.release()
        title = "Đăng kí khám bệnh"
        showBackButton()
        config(dropdown: hiDropdown, for: hIIdTextfield)
        config(dropdown: exTypeDropdown, for: exTypeTextfield)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.paintentTextfield.text = BookingInfo.paintent.fullName
    }
    
    fileprivate func config(dropdown: DropDown, for textview: UITextField) {
        dropdown.direction = .bottom
        dropdown.anchorView = textview
        dropdown.cellHeight = textview.plainView.bounds.height
        dropdown.animationduration = 0.2
        dropdown.bottomOffset.y = textview.plainView.bounds.height

        switch dropdown {
        case hiDropdown:
            dropdown.dataSource = [Constant.yes, Constant.no]
            dropdown.selectionAction =  { (index: Int, item: String) in
                print(item)
                self.hIIdTextfield.text = item
                if item == Constant.yes {
                    /// Hiện pop up cập nhật bảo hiểm
                    let vc = MyStoryboard.bookingStoryboard.instantiateViewController(withIdentifier: "HIUPdateViewController") as! HIUPdateViewController
                    vc.delegate = self
                    self.tabBarController?.view.addSubview(vc.view)
                    self.tabBarController?.addChildViewController(vc)
                } else {
                    BookingInfo.didUseHI = false
                }
            }
            break
            
        case exTypeDropdown:
            dropdown.dataSource = exTypeArray
            dropdown.selectionAction =  { (index: Int, item: String) in
                print(item)
                self.exTypeTextfield.text = item
                self.expDocOrSpecialtyTextfield.text = ""
                self.dateAndTimeTextfield.text = ""
                if item == Expert {
                    // Cho luồng KHÁM CHUYÊN GIA
                    self.ExpDocOrSpecialtyLabel.text = "5. Chuyên gia"
                    self.expDocOrSpecialtyTextfield.placeholder = "Chọn chuyên gia"
                } else {
                    // Luồng khám thông thường và dịch vụ
                    self.ExpDocOrSpecialtyLabel.text = "5. Chuyên khoa"
                    self.expDocOrSpecialtyTextfield.placeholder = "Chọn chuyên khoa"
                }
                BookingInfo.exTypeName = item  // Gán
                BookingInfo.exTypeId = Constant.exTypeDict[item]! // Gán
            }
            break
            
        default:
            break
        }
    }
        
    fileprivate func showExpDoc() {
        let doctorVc = MyStoryboard.bookingStoryboard.instantiateViewController(withIdentifier: "ExpDoctorViewController") as! ExpDoctorViewController
        let nav = BaseNavigationController(rootViewController: doctorVc)
        doctorVc.delegate = self
        doctorVc.hospitalId = BookingInfo.hospital.Id
        navigationController?.present(nav, animated: true)
    }
    
    fileprivate func showSpecialty() {
        if hospitalTextfield.text != "" {
            let next = MyStoryboard.bookingStoryboard.instantiateViewController(withIdentifier: "ChooseSpecialtyViewController") as! ChooseSpecialtyViewController
            let nav = BaseNavigationController(rootViewController: next)
            next.delegate = self
            navigationController?.present(nav, animated: true)
        } else {
            showAlert(title: "Lỗi", mess: "Bạn chưa chọn bệnh viện", style: .alert)
        }
    }
    
    public func subString(text: String, offsetBy: Int) -> String {
        let index = text.index(text.startIndex, offsetBy: offsetBy)
        let dateString = text[..<index] // substring
        return String(dateString)
    }
    
    fileprivate func validate() -> Bool {
        guard let hospitalName = hospitalTextfield.text,
            let hiId = hIIdTextfield.text,
            let exType = exTypeTextfield.text,
            let expDocNameOrSpecialtyName = expDocOrSpecialtyTextfield.text,
            let paintentName = paintentTextfield.text,
            let date = dateAndTimeTextfield.text
        else { return false }
        
        if paintentName == "" {
            showAlert(title: "Lỗi", mess: "Bạn phải chọn bệnh nhân", style: .alert)
        } else if hospitalName == "" {
            showAlert(title: "Lỗi", mess: "Bạn phải chọn Cơ sở khám", style: .alert)
        } else if hiId == "" {
            showAlert(title: "Lỗi", mess: "Bạn phải chọn Bảo hiểm y tế", style: .alert)
        } else if exType == "" {
            showAlert(title: "Lỗi", mess: "Bạn phải chọn Loại hình khám", style: .alert)
        } else if expDocNameOrSpecialtyName == "" {
            if BookingInfo.exTypeId == Constant.exTypeDict[Expert] {
                showAlert(title: "Lỗi", mess: "Bạn phải chọn Chuyên gia", style: .alert)
            } else {
                showAlert(title: "Lỗi", mess: "Bạn phải chọn Chuyên khoa", style: .alert)
            }
        } else if date == "" {
            showAlert(title: "Lỗi", mess: "Bạn phải chọn Ngày giờ", style: .alert)
        } else {
            return true
        }
        return false
    }
}

// API METHODS:
extension BookingViewController {
    
    /** Lấy Id lịch khám */
    fileprivate func getSchedulerId() {
        let param : Parameters = ["CustomerId": MyUser.id,
                                  "HospitalId": BookingInfo.hospital.Id,
                                  "HealthCareId": BookingInfo.specialty.Id,
                                  "IsMorning": true,
                                  "Date": subString(text: BookingInfo.scheduler.Date, offsetBy: 10),
                                  "Type": BookingInfo.exTypeId
        ]
        let completionHandler : ((DataResponse<JSON>) -> Void) = { response in
            MBProgressHUD.hide(for: self.view, animated: true)
            if response.result.isSuccess {
                guard let data = response.value?.dictionaryObject else { return }
                let match = MatchModel(data: data)
                print(match.schedulerId)
                BookingInfo.match = match // Gán
            } else {
                self.showAlert(title: "Lỗi", mess: response.error.debugDescription, style: .alert)
            }
        }
        let uRL = URL(string: API.createExaminationNote)!
        MBProgressHUD.showAdded(to: self.view, animated: true)
        Alamofire.request(uRL, method: .post, parameters: param, encoding: JSONEncoding.default).responseSwiftyJSON(completionHandler: completionHandler)
    }
    
    
    /** Tạo phiếu hẹn cho luồng thông thường và dịch vụ
     Push qua màn hình phiếu hẹn nếu có kq trả về */
    fileprivate func createExamninationNote() {
        let api = URL(string: API.getFirstAppointment)!
        let param : Parameters = [
            "HasHealthInsurance": BookingInfo.didUseHI,
            "HospitalId" : BookingInfo.hospital.Id,
            "HealthCareSchedulerId": BookingInfo.match.schedulerId,
            "ServiceId" : 1,
            "CustomerId": (BookingInfo.paintent.id),
            "PatientId": (BookingInfo.paintent.id),
            "DoctorId": BookingInfo.doctor.id,
            "Type": BookingInfo.exTypeId
        ]
        let completionHandler = { (response: DataResponse<JSON>) -> Void in
            MBProgressHUD.hide(for: self.view, animated: true)
            print(response)
            if response.result.isSuccess {
                guard let data = response.value?.dictionaryObject else {return}
                let newAppointment = Appointment(data: data)
                BookingInfo.appointment = newAppointment  // Gán
                print(newAppointment.service.Code)
                let vc = MyStoryboard.mainStoryboard.instantiateViewController(withIdentifier: "FirstAppointmentViewController") as! FirstAppointmentViewController
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                self.showAlert(title: "Lỗi", mess: response.error.debugDescription, style: .alert)
            }
        }
        MBProgressHUD.showAdded(to: view, animated: true)
        Alamofire.request(api, method: .post, parameters: param, encoding: JSONEncoding.default).responseSwiftyJSON(completionHandler: completionHandler)
    }
    
    
    /** Tạo phiếu hẹn với bác sĩ
     Push qua màn hình phiếu hẹn nếu có kq trả về */
    fileprivate func createExaminationNoteWithDoctor() {
        let api = URL(string: API.getFirstAppointment)!
        let param : Parameters = [
            "HasHealthInsurance": BookingInfo.didUseHI,
            "HealthCareSchedulerId": BookingInfo.time.timeId, /// thay HealthcareSchedulerId bằng time id
            "ServiceId" : 1,
            "CustomerId": (BookingInfo.paintent.id),
            "PatientId": (BookingInfo.paintent.id),
            "DoctorId": BookingInfo.doctor.id,
            "Type": BookingInfo.exTypeId
        ]
        let completionHandler = { (response: DataResponse<JSON>) -> Void in
            MBProgressHUD.hide(for: self.view, animated: true)
            if response.result.isSuccess {
                if let data = response.value?.dictionaryObject {
                    let newAppointment = Appointment(data: data)
                    BookingInfo.appointment = newAppointment  // Gán
                    print(newAppointment.service.Code)
                    let vc = MyStoryboard.mainStoryboard.instantiateViewController(withIdentifier: "FirstAppointmentViewController") as! FirstAppointmentViewController
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    self.showAlert(title: "Lỗi", mess: response.description, style: .alert)
                }
            } else {
                self.showAlert(title: "Lỗi", mess: response.error.debugDescription, style: .alert)
            }
            }
        MBProgressHUD.showAdded(to: view, animated: true)
        Alamofire.request(api, method: .post, parameters: param, encoding: JSONEncoding.default).responseSwiftyJSON(completionHandler: completionHandler)
    }
}

// MARK: DELEGATE METHODS.
extension BookingViewController: HospitalViewControllerDelegate {
    func didChooseHospital(hospital: Hospital) {
        BookingInfo.hospital = hospital // Gán
        self.hospitalTextfield.text = hospital.Name
        
        /// Reset Textfield
        self.expDocOrSpecialtyTextfield.text = ""
        self.exTypeTextfield.text = ""
        self.dateAndTimeTextfield.text = ""
        
        /// reset Dropdown
        guard let index = exTypeDropdown.indexPathForSelectedRow else {return}
        self.exTypeDropdown.deselectRow(index.row)
    }
}

extension BookingViewController: ChooseSpecialtyViewControllerDelegate {
    func didChooseSpecialty(specialty: Specialty) {
        BookingInfo.specialty = specialty // Gán
        self.expDocOrSpecialtyTextfield.text = specialty.Name
        /// reset date
        self.dateAndTimeTextfield.text = ""
    }
}

extension BookingViewController: ExpDoctorViewControllerDelegate {
    func didSelectDoctor(doctor: Doctor) {
        BookingInfo.doctor = doctor  /// Gán
        self.expDocOrSpecialtyTextfield.text = doctor.fullName
        /// reset date
        self.dateAndTimeTextfield.text = ""
    }
}

extension BookingViewController: SchedulersViewControllerDelegate {
    func didSelectTime(time: HealthCareScheduler.Time ) {
        BookingInfo.time = time  /// Gán
///        dateAndTimeTextfield.text = time.from
    }
    
    func didSelectScheduler(scheduler: HealthCareScheduler) {
        BookingInfo.scheduler = scheduler /// Gán
        dateAndTimeTextfield.text = scheduler.DateView
        
        if BookingInfo.exTypeId != Constant.exTypeDict[Expert] {
            /** LẤy id lịch sau khi chọn ngày
             cho luồng thông thường và dịch vụ */
            getSchedulerId()
        }
    }
}

extension BookingViewController: HIUPdateViewControllerDelegate {
    func didSelectUseInsurance(didUsed: Bool, hiid: String) {
        BookingInfo.didUseHI = didUsed  // Gán
        BookingInfo.hiid = hiid // Gán
        MyUser.insuranceId = hiid // Gán vào MyUser
        UserDefaults.standard.set(hiid, forKey: UserInsurance) // Gán vào UserDefaults
        hIIdTextfield.text = didUsed ? "Có" : "Không"
        hiDropdown.selectRow(didUsed ? 0 : 1)
    }
}















