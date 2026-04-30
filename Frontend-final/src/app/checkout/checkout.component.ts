import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CartService, CartItem } from '../services/cart.service';
import { ProfileService, Address } from '../services/profile.service';
import { OrderService } from '../services/order.service';
import { AuthService } from '../services/auth.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { PhoneValidator } from '../phone-validator';

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

  // Notification state
  showSuccessNotification: boolean = false;
  showErrorNotification: boolean = false;
  successMessage: string = '';
  errorMessage: string = '';

  // Saved addresses from backend
  savedAddresses: Address[] = [];
  selectedAddressId: number = 0;

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
    private cartService: CartService,
    private profileService: ProfileService,
    private orderService: OrderService,
    private authService: AuthService
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

  // Phone number input handler - auto-format as user types
  onPhoneInput(event: any): void {
    const input = event.target.value;
    this.customerData.phone = PhoneValidator.formatAsTyping(input);
  }

  placeOrder(): void {
    if (this.cartItems.length === 0) {
      this.showError('A kosár üres!');
      return;
    }

    if (!this.isFormValid()) {
      this.showError('Töltsd ki az összes kötelező mezőt!');
      return;
    }

    // Validate phone number
    if (!PhoneValidator.isValid(this.customerData.phone)) {
      this.showError(PhoneValidator.getErrorMessage(this.customerData.phone));
      return;
    }

    if (this.selectedAddressId === 0) {
      this.showError('Válassz ki egy szállítási címet!');
      return;
    }

    console.log('📦 Placing order with addressId:', this.selectedAddressId);

    // Call checkout endpoint
    this.orderService.createOrder({
      addressId: this.selectedAddressId,
      totalPrice: this.getTotal(),
      status: 'pending',
      items: this.cartItems.map(item => ({
        productId: item.product_id,
        quantity: item.quantity,
        price: item.product_p_price
      }))
    }).subscribe({
      next: (response) => {
        console.log('✅ Order created:', response);
        
        if (response.status === 'OrderCreated' || response.statusCode === 201) {
          // Clear cart after successful order
          this.cartService.clearCart().subscribe();
          
          this.showSuccess(`Rendelés leadva! Rendelésszám: ${response.orderId}`, 3000);
          setTimeout(() => {
            this.router.navigate(['/profile']);
          }, 3000);
        } else {
          this.showError('Hiba történt a rendelés leadása során!');
        }
      },
      error: (err) => {
        console.error('❌ Error placing order:', err);
        this.showError('Hiba történt: ' + (err.error?.message || err.message));
      }
    });
  }

  continueShopping(): void {
    this.router.navigate(['/products']);
  }

  goBackToCart(): void {
    this.router.navigate(['/mainpage']);
  }

  useSavedCustomerData(): void {
    console.log('📥 Loading saved customer data...');
    
    // Try to load from backend first
    this.profileService.getUserProfile().subscribe({
      next: (user) => {
        if (user) {
          this.customerData.lastName = user.username || '';
          this.customerData.firstName = user.teljesnev || '';
          this.customerData.email = user.email || '';
          this.customerData.phone = user.phone || '';
          console.log('✅ Customer data loaded from backend:', this.customerData);
        } else {
          // Fallback to localStorage if backend returns null
          this.loadFromLocalStorage();
        }
      },
      error: (err) => {
        console.error('❌ Backend error, using localStorage fallback:', err);
        // Fallback to localStorage on error
        this.loadFromLocalStorage();
      }
    });
  }

  private loadFromLocalStorage(): void {
    const user = this.authService.getCurrentUser();
    if (user) {
      this.customerData.lastName = user.username || '';
      this.customerData.firstName = user.teljesnev || '';
      this.customerData.email = user.email || '';
      this.customerData.phone = user.phone || '';
      console.log('✅ Customer data loaded from localStorage:', this.customerData);
    } else {
      this.showError('Nem sikerült betölteni a felhasználói adatokat!');
    }
  }

  useSavedAddress(): void {
    console.log('📥 Loading saved addresses from backend...');
    
    this.profileService.getAddresses().subscribe({
      next: (addresses) => {
        this.savedAddresses = addresses;
        console.log('✅ Addresses loaded:', addresses.length);
        
        // Auto-select default address if exists
        const defaultAddr = addresses.find(a => a.isDefault);
        if (defaultAddr) {
          this.selectSavedAddress(defaultAddr.id);
        } else if (addresses.length > 0) {
          this.selectSavedAddress(addresses[0].id);
        }
      },
      error: (err) => {
        console.error('❌ Error loading addresses:', err);
        this.showError('Nem sikerült betölteni a mentett címeket!');
      }
    });
  }

  selectSavedAddress(addressId: number): void {
    this.selectedAddressId = addressId;
    const address = this.savedAddresses.find(a => a.id === addressId);
    
    if (address) {
      this.deliveryAddress.country = address.country;
      this.deliveryAddress.postalCode = address.postalCode;
      this.deliveryAddress.city = address.city;
      this.deliveryAddress.street = address.street;
      
      console.log('✅ Address selected:', address);
    }
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

  // Notification helpers
  private showSuccess(message: string, duration: number = 2000): void {
    this.successMessage = message;
    this.showSuccessNotification = true;
    setTimeout(() => {
      this.showSuccessNotification = false;
    }, duration);
  }

  private showError(message: string, duration: number = 3000): void {
    this.errorMessage = message;
    this.showErrorNotification = true;
    setTimeout(() => {
      this.showErrorNotification = false;
    }, duration);
  }
}