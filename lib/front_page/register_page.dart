import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/loading_popup.dart';

import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:image/image.dart' as img;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => controller.clear(),
      );
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _unitAddressController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedGender;
  int? _selectedCountry;
  final List<DropdownMenuItem<int>> _regionItems = [];
  int? _selectedRegion;
  final List<DropdownMenuItem<int>> _provinceItems = [];
  int? _selectedProvince;
  final List<DropdownMenuItem<int>> _cityItems = [];
  int? _selectedCity;
  final List<DropdownMenuItem<int>> _barangayItems = [];
  int? _selectedBarangay;
  final TextEditingController _birthdayController = TextEditingController();
  bool _obscurePassText = true;
  bool _obscureConfirmPassText = true;
  File? _image;
  String _otpcode = '';
  String _verificationId = '';

  Future<Map<String, Uint8List>> _resizeImage(File image) async {
    // Decode the image

    final img.Image? decodedImage = img.decodeImage(await image.readAsBytes());

    // Crop the image to a 1x1 aspect ratio
    int imgWidth = decodedImage!.width;
    int imgHeight = decodedImage.height;
    int cropSize = imgWidth > imgHeight ? imgHeight : imgWidth;

    final croppedImage = img.copyCrop(decodedImage,
        height: cropSize,
        width: cropSize,
        x: (imgWidth - cropSize) ~/ 2,
        y: (imgHeight - cropSize) ~/ 2);

    // Resize the image to 500x500 pixels
    final normalImage = img.encodeJpg(
        img.copyResize(croppedImage, width: 500, height: 500),
        quality: 90);

    // Resize the image to 96x96 pixels
    final thumbnailImage = img.encodeJpg(
        img.copyResize(croppedImage, width: 96, height: 96),
        quality: 70);

    return {
      'normal': Uint8List.fromList(normalImage),
      'thumbnail': Uint8List.fromList(thumbnailImage)
    };
  }

  Future _registerUser(BuildContext context) async {
    // Implement your registration logic here
    String firstName = _firstNameController.text;
    String middleName = _middleNameController.text;
    String lastName = _lastNameController.text;
    String number = _numberController.text;
    String email = _emailController.text;
    String unitAddress = _unitAddressController.text;
    String address = _addressController.text;
    String zipCode = _zipCodeController.text;
    String username = _usernameController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // Check if the fields are empty
    if (firstName.isEmpty ||
        middleName.isEmpty ||
        lastName.isEmpty ||
        number.isEmpty ||
        email.isEmpty ||
        unitAddress.isEmpty ||
        address.isEmpty ||
        zipCode.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        _selectedGender == null ||
        _selectedCountry == null ||
        _selectedRegion == null ||
        _selectedProvince == null ||
        _selectedCity == null ||
        _selectedBarangay == null ||
        _birthdayController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }

    // Check if the password and confirm password are the same
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
        ),
      );
      return;
    }

    // Check if the password is at least 8 characters long
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long'),
        ),
      );
      return;
    }

    // Check if the email is a valid email address
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email must be a valid email address'),
        ),
      );
      return;
    }

    // Check if the number is a valid number
    // valid number is 11 digits or 13 digits with +639
    if (!RegExp(r'^[0-9]{11}$').hasMatch(number) &&
        !RegExp(r'^\+63[0-9]{10}$').hasMatch(number)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Number must be a valid number'),
        ),
      );
      return;
    }

    // Check if the zip code is a 4 digit number
    if (!RegExp(r'^[0-9]{4}$').hasMatch(zipCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zip code must be a 4 digit number'),
        ),
      );
      return;
    }

    // Check if the username is valid
    if (!RegExp(r'^[a-zA-Z0-9_]{4,}$').hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username must not contain special characters'),
        ),
      );
      return;
    }

    showLoadingPopup(context);

    // Perform registration process
    FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: email,
      password: password,
    )
        .then((value) async {
      // Registration successful
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(value.user!.uid)
          .set({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'gender': _selectedGender,
        'birthday': _birthdayController.text,
        'number': number,
        'email': email,
        'country': _selectedCountry,
        'region': _selectedRegion,
        'province': _selectedProvince,
        'city': _selectedCity,
        'barangay': _selectedBarangay,
        'unitAddress': unitAddress,
        'address': address,
        'zipCode': zipCode,
        'username': username,
        'profileImage': '',
        'thumbProfileImage': '',
      });

      Reference ref =
          FirebaseStorage.instance.ref().child('images').child(value.user!.uid);

      Map<String, Uint8List> bytes = await _resizeImage(_image!);

      // Upload the resized image
      UploadTask uploadTask =
          ref.child('profile_image').putData(bytes['normal']!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Upload the resized thumbnail image
      uploadTask =
          ref.child('thumb_profile_image').putData(bytes['thumbnail']!);
      taskSnapshot = await uploadTask.whenComplete(() => null);
      String thumbImageUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(value.user!.uid)
          .update({
        'profileImage': imageUrl,
        'thumbProfileImage': thumbImageUrl,
      });

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: number,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.currentUser
              ?.updatePhoneNumber(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          Navigator.of(context).pop();
          if (e.code == 'invalid-phone-number') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The provided phone number is not valid.'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('An error occurred while verifying the phone number.'),
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      if (!context.mounted) return;

      Navigator.of(context).pop();

      showDialog(
        context: context,
        barrierDismissible: false, // Make the dialog not cancellable
        builder: (BuildContext context) {
          return PopScope(
            canPop: false, // Disable back button
            child: AlertDialog(
              title: const Text('Enter OTP'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Enter the OTP code sent to your number $number.'),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _otpcode = value;
                      });
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(FluentIcons.number_symbol_24_filled),
                      labelText: 'OTP code',
                      hintText: 'Enter OTP code',
                      helperText: 'OTP code must be a 6 digit number',
                      filled: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Submit'),
                  onPressed: () async {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    showLoadingPopup(context);

                    try {
                      final AuthCredential credential =
                          PhoneAuthProvider.credential(
                              verificationId: _verificationId, smsCode: _otpcode);
                      await FirebaseAuth.instance.currentUser!
                          .linkWithCredential(credential);
                          
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        arguments: {'from': widget},
                        (Route<dynamic> route) => false,
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account created successfully'),
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error occurred: ${error.toString()}'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    }).catchError((error) {
      // Registration failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
        ),
      );
    });
  }

  Future _getRegions() async {
    // get the regions from the database
    Database db = await openDatabase('address.db', readOnly: true);

    await db.query('refRegion').then((value) {
      setState(() {
        _regionItems.clear();
        for (var region in value) {
          _regionItems.add(DropdownMenuItem(
            value: region['regCode'] as int?,
            child: Text(
              region['regDesc'] as String,
              overflow: TextOverflow.ellipsis,
            ),
          ));
        }
      });
    });
  }

  Future _getProvinces(int region) async {
    // get the regions from the database
    Database db = await openDatabase('address.db', readOnly: true);

    await db.query('refProvince',
        where: 'regCode = ?', whereArgs: [region]).then((value) {
      setState(() {
        _provinceItems.clear();
        for (var region in value) {
          _provinceItems.add(DropdownMenuItem(
            value: region['provCode'] as int?,
            child: Text(
              region['provDesc'] as String,
              overflow: TextOverflow.ellipsis,
            ),
          ));
        }
      });
    });
  }

  Future _getCities(int province) async {
    // get the regions from the database
    Database db = await openDatabase('address.db', readOnly: true);

    await db.query('refCitymun',
        where: 'provCode = ?', whereArgs: [province]).then((value) {
      setState(() {
        _cityItems.clear();
        for (var region in value) {
          _cityItems.add(DropdownMenuItem(
            value: region['citymunCode'] as int?,
            child: Text(
              region['citymunDesc'] as String,
              overflow: TextOverflow.ellipsis,
            ),
          ));
        }
      });
    });
  }

  Future _getBarangays(int city) async {
    Database db = await openDatabase('address.db', readOnly: true);

    await db.query('refBarangay',
        where: 'citymunCode = ?', whereArgs: [city]).then((value) {
      setState(() {
        _barangayItems.clear();
        for (var region in value) {
          _barangayItems.add(DropdownMenuItem(
            value: region['brgyCode'] as int?,
            child: Text(
              region['brgyDesc'] as String,
              overflow: TextOverflow.ellipsis,
            ),
          ));
        }
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverAppBar.large(
          title: Text('Register'),
          actions: [],
        ),
        SliverToBoxAdapter(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // add text header
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // image picker
              // show image
              Padding(
                padding: const EdgeInsets.only(top: 16),
                // create a circular button that contains image
                child: FilledButton.tonal(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    splashFactory: NoSplash.splashFactory,
                    shape: const CircleBorder(),
                    minimumSize: const Size(250, 250),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: _image != null
                                ? FileImage(_image!)
                                : const AssetImage('assets/transparent.png')
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      _image == null
                          ? const Icon(FluentIcons.camera_add_24_filled,
                              size: 30)
                          : Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.75),
                                ),
                                child: const Icon(
                                    FluentIcons.camera_edit_20_filled,
                                    size: 30),
                              ),
                            ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.5),
                            onTap: () {
                              _pickImage(ImageSource.gallery);
                            },
                            borderRadius:
                                BorderRadius.circular(125), // Add this line
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, top: 16),
                child: TextField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    suffixIcon: _ClearButton(controller: _firstNameController),
                    labelText: 'First name',
                    hintText: 'Enter your first name',
                    fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                    filled: true,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 18.0, right: 9.0, top: 16.0),
                      child: TextField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          suffixIcon:
                              _ClearButton(controller: _lastNameController),
                          labelText: 'Last name',
                          hintText: 'Enter your last name',
                          fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 9.0, right: 18.0, top: 16.0),
                      child: TextField(
                        controller: _middleNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          suffixIcon:
                              _ClearButton(controller: _middleNameController),
                          labelText: 'Middle name',
                          hintText: 'Enter your Middle name',
                          fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30.0, top: 9.0),
                  child: Text(
                    'Name should not contain special characters',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.9),
                    ),
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(left: 18, right: 18, top: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(FluentIcons.person_24_filled),
                      labelText: 'Gender',
                      fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                      filled: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Male',
                        child: Text('Male'),
                      ),
                      DropdownMenuItem(
                        value: 'Female',
                        child: Text('Female'),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text('Other'),
                      ),
                    ],
                  )),
              Padding(
                padding: const EdgeInsets.only(
                    left: 18, right: 18, top: 16, bottom: 30),
                child: TextField(
                  controller: _birthdayController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FluentIcons.calendar_24_filled),
                    suffixIcon: _ClearButton(controller: _birthdayController),
                    labelText: 'Birthday',
                    hintText: 'Select your birthday',
                    fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                    filled: true,
                  ),
                  onTap: () {
                    showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(_birthdayController.text) ??
                              DateTime.now()
                                  .subtract(const Duration(days: 365 * 18)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now()
                          .subtract(const Duration(days: 365 * 18)),
                    ).then((value) {
                      if (value != null) {
                        _birthdayController.text =
                            value.toString().substring(0, 10);
                      }
                    });
                  },
                  readOnly: true,
                ),
              ),
              // add text header
              const Text(
                'Address Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 18.0, right: 9.0, top: 16.0),
                      child: DropdownButtonFormField<int>(
                        value: _selectedCountry,
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedBarangay = null;
                            _barangayItems.clear();
                            _selectedCity = null;
                            _cityItems.clear();
                            _selectedProvince = null;
                            _provinceItems.clear();
                            _selectedRegion = null;
                            _regionItems.clear();
                            _selectedCountry = value;
                            _getRegions();
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Country',
                          fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                          filled: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Philippines'),
                          )
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 9.0, right: 18.0, top: 16.0),
                      child: DropdownButtonFormField<int>(
                        value: _selectedRegion,
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedBarangay = null;
                            _barangayItems.clear();
                            _selectedCity = null;
                            _cityItems.clear();
                            _selectedProvince = null;
                            _provinceItems.clear();
                            _selectedRegion = value;
                            _getProvinces(value!);
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Region',
                          fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                          filled: true,
                        ),
                        items: _regionItems,
                      ),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 18.0, right: 9.0, top: 16.0),
                      child: DropdownButtonFormField<int>(
                        value: _selectedProvince,
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedBarangay = null;
                            _barangayItems.clear();
                            _selectedCity = null;
                            _cityItems.clear();
                            _selectedProvince = value;
                            _getCities(value!);
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Province',
                          filled: true,                    
                          fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                        ),
                        items: _provinceItems,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 9.0, right: 18.0, top: 16.0),
                      child: DropdownButtonFormField<int>(
                        value: _selectedCity,
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedBarangay = null;
                            _barangayItems.clear();
                            _selectedCity = value;
                            _getBarangays(value!);
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'City/Municipality',
                          fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                          filled: true,
                        ),
                        items: _cityItems,
                      ),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 18.0, right: 9.0, top: 16.0),
                      child: DropdownButtonFormField<int>(
                        value: _selectedBarangay,
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedBarangay = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Barangay',
                          fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                          filled: true,
                        ),
                        items: _barangayItems,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 9.0, right: 18.0, top: 16.0),
                      child: TextField(
                        controller: _unitAddressController,
                        decoration: InputDecoration(
                          suffixIcon:
                              _ClearButton(controller: _unitAddressController),
                          labelText: 'Unit/Street/Building',
                          hintText: 'Enter your full address',
                          fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, top: 16),
                child: TextField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FluentIcons.location_24_filled),
                    suffixIcon: _ClearButton(controller: _addressController),
                    labelText: 'Full address',
                    hintText: 'Enter your full address',
                    helperText: 'Address must not contain special characters',
                    fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                    filled: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 18, right: 18, top: 16, bottom: 30),
                child: TextField(
                  controller: _zipCodeController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FluentIcons.number_symbol_24_filled),
                    suffixIcon: _ClearButton(controller: _zipCodeController),
                    labelText: 'Zip code',
                    hintText: 'Enter your zip code',
                    helperText: 'Zip code must be a 4 digit number',
                    fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                    filled: true,
                  ),
                ),
              ),
              // add text header
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, top: 16),
                child: TextField(
                  controller: _numberController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FluentIcons.call_24_filled),
                    suffixIcon: _ClearButton(controller: _numberController),
                    labelText: 'Number',
                    hintText: 'Enter your number',
                    helperText: 'Number must be a valid number',
                    fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                    filled: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 18, right: 18, top: 16, bottom: 30),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FluentIcons.mail_24_filled),
                    suffixIcon: _ClearButton(controller: _emailController),
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    helperText: 'Email must be a valid email address',
                    fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                    filled: true,
                  ),
                ),
              ),
              // add text header
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, top: 16),
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FluentIcons.person_24_filled),
                    suffixIcon: _ClearButton(controller: _usernameController),
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    helperText: 'Username must not contain special characters',
                    fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                    filled: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 18, right: 18, bottom: 16, top: 16),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassText,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FluentIcons.lock_closed_24_filled),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassText
                            ? FluentIcons.eye_24_filled
                            : FluentIcons.eye_off_24_filled,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassText = !_obscurePassText;
                        });
                      },
                    ),
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    helperText: 'Password must be at least 8 characters long',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 18, right: 18, bottom: 30),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassText,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FluentIcons.lock_closed_24_filled),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassText
                            ? FluentIcons.eye_24_filled
                            : FluentIcons.eye_off_24_filled,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassText = !_obscureConfirmPassText;
                        });
                      },
                    ),
                    labelText: 'Confirm Password',
                    hintText: 'Enter your confirm password',
                    helperText: 'Confirm password must be the same as password',
                    fillColor: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
                    filled: true,
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: TextButton.styleFrom(
                    surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                  ),
                  onPressed: () => _registerUser(context),
                  child: const Text('Register'),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ],
    ));
  }
}
