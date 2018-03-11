//
//  Constant.swift
//  BAKCO VanKhang
//
//  Created by Kiet on 1/26/18.
//  Copyright © 2018 Pham An. All rights reserved.
//

import Foundation


let _GetServiceDetailURL = "http://api.vkhealth.vn/api/BkFamilyDoctor/GetServiceDetails"
let _TrueconfLink = "http://vkhs.vn/index.html#/tcs"
let _SOSEmergencyApi = "http://api.vkhs.vn/api/SOSCall/CallSOS"
let _GetHealthCareSchedulerApi = "http://api.vkhs.vn/api/BkHealthCareScheduler/GetByHospitalHealthCareId"
let _GetMatchApi = "http://api.vkhs.vn/api/BkMedicalExaminationNote/CreateForMember"
let _GetFirstAppointmentApi = "http://api.vkhs.vn/api/BkMedicalExaminationNote/Create"
let _GetScheduleApi = "http://api.vkhs.vn/api/BkCustomer/GetSchedulerCustomer"
let _RegisterURL = "http://api.vkhs.vn/api/BkCustomer/Create"



var _userName = ""
var _userId = 0
var _userAddress = ""
var _userInsurance = ""
var _userPhone = ""
var _userEmail = ""
var _userBirthday = ""

var userDict = [String : User]()