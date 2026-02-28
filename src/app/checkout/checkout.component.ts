import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CartService, CartItem } from '../services/cart.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";

interface DeliveryOption {
  id: string;
  name: string;
  iconPath: string;  // ← Changed from 'icon' to 'iconPath'
  price: number;
  estimatedDays: string;
}

interface PaymentMethod {
  id: string;
  name: string;
  iconPath: string;  // ← Changed from 'icon' to 'iconPath'
}

@Component({
  selector: 'app-checkout',
  standalone: true,
  imports: [CommonModule, FormsModule, HeaderComponent, FooterComponent],
  templateUrl: './checkout.component.html',
  styleUrl: './checkout.component.css'
})
export class CheckoutComponent implements OnInit {
  cartItems: CartItem[] = [];
  selectedDeliveryMethod: string = 'store';
  selectedPaymentMethod: string = 'card';

  // Customer data
  customerData = {
    lastName: '',
    firstName: '',
    email: '',
    phone: ''
  };

  // Delivery address
  deliveryAddress = {
    country: '',
    postalCode: '',
    city: '',
    street: ''
  };

  deliveryOptions: DeliveryOption[] = [
    {
      id: 'store',
      name: 'Átvétel boltban',
      iconPath: 'assets/icons8-store-64.png',
      price: 0,
      estimatedDays: '3 munkanap'
    },
    {
      id: 'home',
      name: 'Házhozszállítás',
      iconPath: 'assets/icons8-house-64.png',
      price: 1990,
      estimatedDays: '3-5 munkanap'
    },
    {
      id: 'foxpost',
      name: 'FoxPost csomagpont',
      iconPath: 'assets/foxpostimg.png',
      price: 990,
      estimatedDays: '2-4 munkanap'
    },
    {
      id: 'mpl-auto',
      name: 'MPL automata',
      iconPath: 'assets/mpl_logo.png',  // ← Ugyanaz mint FoxPost
      price: 890,
      estimatedDays: '2-3 munkanap'
    },
    {
      id: 'coretech',
      name: 'CoreTech átvevőpont',
      iconPath: 'assets/CoreTechLogoKek.png',  // ← Ugyanaz mint bolt
      price: 0,
      estimatedDays: '2-3 munkanap'
    },
    {
      id: 'mpl-courier',
      name: 'MPL futár',
      iconPath: 'assets/mpl_logo.png',  // ← Ugyanaz mint házhozszállítás
      price: 1490,
      estimatedDays: '1-2 munkanap'
    },
    {
      id: 'dpd',
      name: 'DPD express',
      iconPath: 'assets/dpdlogo.png',  // ← Ugyanaz mint házhozszállítás
      price: 2490,
      estimatedDays: '1 munkanap'
    }
  ];

  paymentMethods: PaymentMethod[] = [
    {
      id: 'card',
      name: 'Bankkártyával online',
      iconPath: 'assets/MasterCard_Logo.svg.png'  // ← PNG icon path
    },
    {
      id: 'applepay',
      name: 'Apple Pay',
      iconPath: 'assets/applepaylogo.png'  // ← PNG icon path
    },
    {
      id: 'paypal',
      name: 'PayPal',
      iconPath: 'assets/paypallogo.png'  // ← PNG icon path
    }
  ];

  constructor(
    private router: Router,
    private cartService: CartService
  ) {}

  ngOnInit(): void {
    this.cartService.cart$.subscribe(items => {
      this.cartItems = items;
    });
  }

  selectDeliveryMethod(id: string): void {
    this.selectedDeliveryMethod = id;
  }

  selectPaymentMethod(id: string): void {
    this.selectedPaymentMethod = id;
  }

  getSelectedDeliveryOption(): DeliveryOption | undefined {
    return this.deliveryOptions.find(opt => opt.id === this.selectedDeliveryMethod);
  }

  // Calculate subtotal (products only)
  getSubtotal(): number {
    return this.cartItems.reduce((sum, item) => {
      return sum + (item.product_p_price * item.quantity);
    }, 0);
  }

  // Get delivery price
  getDeliveryPrice(): number {
    const selectedOption = this.getSelectedDeliveryOption();
    return selectedOption ? selectedOption.price : 0;
  }

  // Calculate total (subtotal + delivery)
  getTotal(): number {
    return this.getSubtotal() + this.getDeliveryPrice();
  }

  formatPrice(price: number): string {
    return new Intl.NumberFormat('hu-HU', {
      style: 'currency',
      currency: 'HUF',
      minimumFractionDigits: 0
    }).format(price);
  }

  placeOrder(): void {
    if (this.cartItems.length === 0) {
      alert('A kosár üres!');
      return;
    }

    const orderData = {
      items: this.cartItems.map(item => ({
        productId: item.product_id,
        productName: item.product_name,
        quantity: item.quantity,
        price: item.product_p_price
      })),
      deliveryMethod: this.selectedDeliveryMethod,
      paymentMethod: this.selectedPaymentMethod,
      subtotal: this.getSubtotal(),
      deliveryFee: this.getDeliveryPrice(),
      total: this.getTotal()
    };

    console.log('Order placed:', orderData);
    alert('Rendelés leadva! (Demo mode)');
    this.router.navigate(['/mainpage']);
  }

  continueShopping(): void {
    this.router.navigate(['/products']);
  }

  goBackToCart(): void {
    this.router.navigate(['/mainpage']);
  }

  useSavedCustomerData(): void {
    console.log('Loading saved customer data...');
    // TODO: Load saved data from profile service
    alert('Mentett adatok betöltése (Fejlesztés alatt)');
  }

  useSavedAddress(): void {
    console.log('Loading saved address...');
    // TODO: Load saved address from profile service
    alert('Mentett cím betöltése (Fejlesztés alatt)');
  }

  isFormValid(): boolean {
    // Check if customer data is filled
    const hasCustomerData = 
      this.customerData.lastName.trim() !== '' &&
      this.customerData.firstName.trim() !== '' &&
      this.customerData.email.trim() !== '' &&
      this.customerData.phone.trim() !== '';

    // Check if delivery address is filled
    const hasDeliveryAddress = 
      this.deliveryAddress.country.trim() !== '' &&
      this.deliveryAddress.postalCode.trim() !== '' &&
      this.deliveryAddress.city.trim() !== '' &&
      this.deliveryAddress.street.trim() !== '';

    // Check if cart has items
    const hasCartItems = this.cartItems.length > 0;

    return hasCustomerData && hasDeliveryAddress && hasCartItems;
  }
}