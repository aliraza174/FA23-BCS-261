class BasicInfo {
  final String fullName;
  final int? established;
  final String type;
  final double? googleRating;

  const BasicInfo({
    required this.fullName,
    this.established,
    required this.type,
    this.googleRating,
  });
}

class ContactDetails {
  final String address;
  final String phone;
  final String mapLink;

  const ContactDetails({
    required this.address,
    required this.phone,
    required this.mapLink,
  });
}

class MenuCategory {
  final String name;
  final String description;
  final double price;
  final List<String> size;

  const MenuCategory({
    required this.name,
    required this.description,
    required this.price,
    required this.size,
  });
}

class RestaurantDataModel {
  final String id;
  final String name;
  final BasicInfo basicInfo;
  final ContactDetails contactDetails;
  final List<MenuCategory> menuCategories;
  final List<String> menuImages;
  final List<String> dealImages;
  final String imageAsset;

  const RestaurantDataModel({
    required this.id,
    required this.name,
    required this.basicInfo,
    required this.contactDetails,
    required this.menuCategories,
    this.menuImages = const [],
    this.dealImages = const [],
    this.imageAsset = '',
  });
}

// List of all restaurant data
final List<RestaurantDataModel> allRestaurants = [
  const RestaurantDataModel(
    id: '1',
    name: 'Meet N Eat',
    basicInfo: BasicInfo(
      fullName: 'Meet N Eat',
      established: 2018,
      type: 'Fast Food & Pizza',
      googleRating: 4.5,
    ),
    contactDetails: ContactDetails(
      address: 'Opposite Nadra Office, Multan Road, Jahanian',
      phone: '0328-5500112, 0310-5083300',
      mapLink: 'https://maps.app.goo.gl/123',
    ),
    menuCategories: [
      MenuCategory(
        name: 'Oven Baked Wings',
        description: 'Crispy wings with choice of sauce',
        price: 390,
        size: ['6Pcs', '12Pcs'],
      ),
      MenuCategory(
        name: 'Crispy Zinger Burger',
        description: 'Crispy chicken with mayo and lettuce in sesame bun',
        price: 350,
        size: ['Regular'],
      ),
    ],
    menuImages: [
      'assets/images/meetneat1.jpg',
      'assets/images/meetneat2.jpg',
    ],
    dealImages: [
      'assets/images/meetneatdeal1.jpg',
      'assets/images/meetneatDeals2.jpg',
    ],
    imageAsset: 'assets/images/meetneatdeal1.jpg',
  ),
  const RestaurantDataModel(
    id: '2',
    name: 'Crust Bros',
    basicInfo: BasicInfo(
      fullName: 'Crust Bros',
      established: 2019,
      type: 'Pizza & Fast Food',
      googleRating: 4.2,
    ),
    contactDetails: ContactDetails(
      address: 'Loha Bazar, Jahanian',
      phone: '0325-8003399, 0327-8003399',
      mapLink: 'https://maps.app.goo.gl/456',
    ),
    menuCategories: [
      MenuCategory(
        name: 'Special Platter',
        description: '4 Pcs Spin Roll, 6 Pcs Wings, Fries & Dip Sauce',
        price: 1050,
        size: ['Regular'],
      ),
      MenuCategory(
        name: 'Cheese Lover Pizza',
        description: 'Loaded with extra cheese',
        price: 1099,
        size: ['Medium', 'Large'],
      ),
    ],
    menuImages: [
      'assets/images/crustbros1.jpg',
      'assets/images/CrustBros2.jpg',
    ],
    dealImages: [
      'assets/images/restaurant1.jpg',
    ],
    imageAsset: 'assets/images/crustbros1.jpg',
  ),
  const RestaurantDataModel(
    id: '3',
    name: 'Khana Khazana',
    basicInfo: BasicInfo(
      fullName: 'Khana Khazana',
      established: 2017,
      type: 'Pakistani Cuisine',
      googleRating: 4.3,
    ),
    contactDetails: ContactDetails(
      address:
          'Main Super Highway Bahawal Pur Road, Near Total Petrol Pump Jahanian',
      phone: '0345-7277634, 0309-4152186',
      mapLink: 'https://maps.app.goo.gl/789',
    ),
    menuCategories: [
      MenuCategory(
        name: 'KK Special Chicken Handi',
        description: 'Traditional chicken handi with special spices',
        price: 850,
        size: ['Half', 'Full'],
      ),
      MenuCategory(
        name: 'KK Special Mutton Biryani',
        description: 'Aromatic rice with tender mutton pieces',
        price: 500,
        size: ['Half', 'Full'],
      ),
    ],
    menuImages: [
      'assets/images/khanakhazana1.jpg',
      'assets/images/khanakhazana2.jpg',
    ],
    dealImages: [
      'assets/images/restaurant2.jpg',
    ],
    imageAsset: 'assets/images/khanakhazana1.jpg',
  ),
  const RestaurantDataModel(
    id: '4',
    name: 'Miran Jee Food Club (MFC)',
    basicInfo: BasicInfo(
      fullName: 'Miran Jee Food Club',
      established: 2018,
      type: 'Fast Food & Pizza',
      googleRating: 4.4,
    ),
    contactDetails: ContactDetails(
      address: 'Near Ice Factory, Rahim Shah Road, Jahanian',
      phone: '0309-7000178, 0306-7587938',
      mapLink: 'https://maps.app.goo.gl/abc',
    ),
    menuCategories: [
      MenuCategory(
        name: 'Vege Lover Pizza',
        description: 'Fresh vegetable toppings on our special base',
        price: 520,
        size: ['Regular'],
      ),
      MenuCategory(
        name: 'Chicken Tikka Pizza',
        description: 'Topped with special chicken tikka pieces',
        price: 1000,
        size: ['Regular'],
      ),
    ],
    menuImages: [
      'assets/images/mfc.jpg',
      'assets/images/mfc2.jpg',
    ],
    dealImages: [
      'assets/images/mfcdeals.jpg',
      'assets/images/mfcdeals2.jpg',
    ],
    imageAsset: 'assets/images/mfcdeals.jpg',
  ),
  const RestaurantDataModel(
    id: '5',
    name: 'Pizza Slice',
    basicInfo: BasicInfo(
      fullName: 'Pizza Slice',
      established: 2019,
      type: 'Pizza & Fast Food',
      googleRating: 4.0,
    ),
    contactDetails: ContactDetails(
      address: 'Main Khanewall Highway Road, Infront of Qudas Masjid Jahanian',
      phone: '0308-4824792, 0311-4971155, 0303-4971155',
      mapLink: 'https://maps.app.goo.gl/def',
    ),
    menuCategories: [
      MenuCategory(
        name: 'Achari Pizza',
        description: 'Special pizza with achari flavor',
        price: 500,
        size: ['Small', 'Medium'],
      ),
      MenuCategory(
        name: 'Zinger Burger',
        description: 'Crispy zinger with special sauce',
        price: 330,
        size: ['Regular'],
      ),
    ],
    menuImages: [
      'assets/images/pizzaslice1.jpg',
      'assets/images/pizzaslice2.jpg',
    ],
    dealImages: [
      'assets/images/pizzaslice1.jpeg',
      'assets/images/pizzaslicedeals.jpg',
    ],
    imageAsset: 'assets/images/pizzaslice1.jpg',
  ),
  const RestaurantDataModel(
    id: '6',
    name: 'Nawab Hotel',
    basicInfo: BasicInfo(
      fullName: 'Nawab Hotel',
      established: 2015,
      type: 'Pakistani Cuisine',
      googleRating: 4.1,
    ),
    contactDetails: ContactDetails(
      address: 'Main Bazar, Jahanian',
      phone: '0300-1234567',
      mapLink: 'https://maps.app.goo.gl/ghi',
    ),
    menuCategories: [
      MenuCategory(
        name: 'Special Karahi',
        description: 'Traditional karahi with special spices',
        price: 1200,
        size: ['Half', 'Full'],
      ),
      MenuCategory(
        name: 'Chicken Biryani',
        description: 'Flavorful rice with chicken pieces',
        price: 350,
        size: ['Regular'],
      ),
    ],
    menuImages: [
      'assets/images/nawab1.jpg',
      'assets/images/nawab2.jpg',
      'assets/images/nawab3.jpg',
    ],
    dealImages: [
      'assets/images/nawab_hotel_jahanian.jpg',
    ],
    imageAsset: 'assets/images/nawab_hotel_jahanian.jpg',
  ),
  const RestaurantDataModel(
    id: '7',
    name: "Beba's Kitchen",
    basicInfo: BasicInfo(
      fullName: "Beba's Kitchen",
      established: 2020,
      type: 'Fast Food',
      googleRating: 4.2,
    ),
    contactDetails: ContactDetails(
      address: 'Shop #97, Press Club Road, Near Gourmet Cola Agency, Jahanian',
      phone: '0311-4971155, 0303-4971155',
      mapLink: 'https://maps.app.goo.gl/jkl',
    ),
    menuCategories: [
      MenuCategory(
        name: 'Special Pizza',
        description: 'House special pizza with multiple toppings',
        price: 800,
        size: ['Small', 'Medium', 'Large'],
      ),
      MenuCategory(
        name: 'Zinger Burger',
        description: 'Crispy zinger with special sauce',
        price: 170,
        size: ['Regular'],
      ),
    ],
    menuImages: [
      'assets/images/bebaskitchen.jpg',
    ],
    dealImages: [
      'assets/images/bebaskitchen.jpg',
    ],
    imageAsset: 'assets/images/bebaskitchen.jpg',
  ),
  const RestaurantDataModel(
    id: '8',
    name: 'EatWay',
    basicInfo: BasicInfo(
      fullName: 'EatWay',
      established: 2021,
      type: 'Fast Food & Pizza',
      googleRating: 4.3,
    ),
    contactDetails: ContactDetails(
      address: 'Rehmat Villas, Phase 1, Canal Road, Jahanian',
      phone: '0301-0800777, 0310-0800777',
      mapLink: 'https://maps.app.goo.gl/mno',
    ),
    menuCategories: [
      MenuCategory(
        name: 'Cheese Lovers Pizza',
        description: 'Pizza loaded with multiple cheeses',
        price: 1099,
        size: ['Small', 'Medium', 'Large'],
      ),
      MenuCategory(
        name: 'Chicken Supreme',
        description: 'Pizza with premium chicken toppings',
        price: 1299,
        size: ['Small', 'Medium', 'Large'],
      ),
    ],
    menuImages: [
      'assets/images/eatway1.jpg',
      'assets/images/eatway2.jpg',
    ],
    dealImages: [
      'assets/images/eatway.jpg',
      'assets/images/eatwayDeal1.jpg',
      'assets/images/eatwayDeal2.jpg',
    ],
    imageAsset: 'assets/images/eatway.jpg',
  ),
];
