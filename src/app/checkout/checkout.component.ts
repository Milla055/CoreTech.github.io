import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { HeaderComponent } from '../header/header.component';
import { FooterComponent } from '../footer/footer.component';
import { CartService } from '../services/cart.service';
import { AuthService } from '../services/auth.service';
import { OrderService } from '../services/order.service';

interface CartItem {
  product: any;
  quantity: number;
}

interface DeliveryOption {
  id: string;
  name: string;
  icon: string;
  price: number;
  estimatedDays: string;
}

interface PaymentMethod {
  id: string;
  name: string;
  icon: string;
}

@Component({
  selector: 'app-checkout',
  standalone: true,
  imports: [CommonModule, FormsModule, HeaderComponent, FooterComponent],
  templateUrl: './checkout.component.html',
  styleUrl: './checkout.component.css',
})
export class CheckoutComponent implements OnInit {
  // Cart items
  cartItems: CartItem[] = [];
  
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
  
  // Selected options
  selectedDeliveryMethod: string = '';
  selectedPaymentMethod: string = '';
  
  // Delivery options
  deliveryOptions: DeliveryOption[] = [
    {
      id: 'store',
      name: 'Átvétel boltban',
      icon: '🏪',
      price: 0,
      estimatedDays: '3 munkanap'
    },
    {
      id: 'home',
      name: 'Házhozszállítás',
      icon: '🚚',
      price: 1990,
      estimatedDays: '3-5 munkanap'
    },
    {
      id: 'foxpost',
      name: 'FoxPost csomagpont',
      icon: '📦',
      price: 990,
      estimatedDays: '2-4 munkanap'
    },
    {
      id: 'mpl-auto',
      name: 'MPL automata',
      icon: '🤖',
      price: 890,
      estimatedDays: '2-3 munkanap'
    },
    {
      id: 'coretech',
      name: 'CoreTech átvevőpont',
      icon: '🏢',
      price: 0,
      estimatedDays: '2-3 munkanap'
    },
    {
      id: 'mpl-courier',
      name: 'MPL futár',
      icon: '🚴',
      price: 1490,
      estimatedDays: '1-2 munkanap'
    },
    {
      id: 'dpd',
      name: 'DPD express',
      icon: '⚡',
      price: 2490,
      estimatedDays: '1 munkanap'
    }
  ];
  
  // Payment methods
  paymentMethods: PaymentMethod[] = [
    {
      id: 'card',
      name: 'Bankkártyával online',
      icon: '💳'
    },
    {
      id: 'applepay',
      name: 'Apple Pay',
      icon: ''
    },
    {
      id: 'paypal',
      name: 'PayPal',
      icon: ''
    }
  ];

  constructor(
    private router: Router,
    private cartService: CartService,
    private authService: AuthService,
    private orderService: OrderService
  ) {}

  ngOnInit(): void {
    // Check if user is logged in
    if (!this.authService.isLoggedIn()) {
      alert('Kérlek jelentkezz be a rendelés leadásához!');
      this.router.navigate(['/login']);
      return;
    }

    // Load cart items
    this.loadCartItems();
    
    // Set default selections
    this.selectedDeliveryMethod = 'store';
    this.selectedPaymentMethod = 'card';
  }

  loadCartItems(): void {
    this.cartItems = this.cartService.getCartItems();
    
    if (this.cartItems.length === 0) {
      alert('A kosarad üres!');
      this.router.navigate(['/cart']);
    }
  }

  // Load saved customer data from localStorage (from profile page)
  useSavedCustomerData(): void {
    const savedProfile = localStorage.getItem('currentUser');
    
    if (savedProfile) {
      const profile = JSON.parse(savedProfile);
      
      this.customerData.lastName = profile.vezetekNev || '';
      this.customerData.firstName = profile.keresztNev || '';
      this.customerData.email = profile.email || '';
      this.customerData.phone = profile.telefonszam || '';
      
      alert('✅ Mentett adatok betöltve!');
    } else {
      alert('⚠️ Nincs mentett adat!');
    }
  }

  // Load saved delivery address from localStorage (from profile page)
  useSavedAddress(): void {
    const savedProfile = localStorage.getItem('currentUser');
    
    if (savedProfile) {
      const profile = JSON.parse(savedProfile);
      
      if (profile.cim) {
        this.deliveryAddress.country = profile.cim.orszag || '';
        this.deliveryAddress.postalCode = profile.cim.iranyitoszam || '';
        this.deliveryAddress.city = profile.cim.varos || '';
        this.deliveryAddress.street = profile.cim.utcaHazszam || '';
        
        alert('✅ Mentett cím betöltve!');
      } else {
        alert('⚠️ Nincs mentett cím!');
      }
    } else {
      alert('⚠️ Nincs mentett adat!');
    }
  }

  // Select delivery method
  selectDeliveryMethod(methodId: string): void {
    this.selectedDeliveryMethod = methodId;
  }

  // Select payment method
  selectPaymentMethod(methodId: string): void {
    this.selectedPaymentMethod = methodId;
  }

  // Get selected delivery option
  getSelectedDeliveryOption(): DeliveryOption | undefined {
    return this.deliveryOptions.find(opt => opt.id === this.selectedDeliveryMethod);
  }

  // Calculate subtotal (products only)
  getSubtotal(): number {
    return this.cartItems.reduce((sum, item) => {
      return sum + (item.product.pPrice * item.quantity);
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

  // Format price
  formatPrice(price: number): string {
    return Math.round(price).toLocaleString('hu-HU') + ' Ft';
  }

  // Validate form
  isFormValid(): boolean {
    // Check customer data
    if (!this.customerData.lastName || !this.customerData.firstName || 
        !this.customerData.email || !this.customerData.phone) {
      return false;
    }
    
    // Check delivery address (except for store pickup)
    if (this.selectedDeliveryMethod !== 'store' && this.selectedDeliveryMethod !== 'coretech') {
      if (!this.deliveryAddress.country || !this.deliveryAddress.postalCode || 
          !this.deliveryAddress.city || !this.deliveryAddress.street) {
        return false;
      }
    }
    
    // Check selections
    if (!this.selectedDeliveryMethod || !this.selectedPaymentMethod) {
      return false;
    }
    
    return true;
  }

  // Place order
  placeOrder(): void {
    console.log('🛒 Placing order...');
    
    if (!this.isFormValid()) {
      alert('⚠️ Kérlek töltsd ki az összes kötelező mezőt!');
      return;
    }
    
    // Get current user
    const user = this.authService.getCurrentUser();
    if (!user || !user.id) {
      alert('⚠️ Nem található bejelentkezett felhasználó!');
      this.router.navigate(['/login']);
      return;
    }

    const userId = user.id;
    
    // Step 1: Create address first (if needed)
    const needsAddress = this.selectedDeliveryMethod !== 'store' && this.selectedDeliveryMethod !== 'coretech';
    
    if (needsAddress) {
      // Create address
      const addressData = {
        userId: userId,
        street: this.deliveryAddress.street,
        city: this.deliveryAddress.city,
        postalCode: this.deliveryAddress.postalCode,
        country: this.deliveryAddress.country,
        isDefault: false
      };

      console.log('📍 Creating address...', addressData);

      this.orderService.createAddress(addressData).subscribe({
        next: (addressId) => {
          console.log('✅ Address created with ID:', addressId);
          this.createOrderWithAddress(userId, addressId);
        },
        error: (err) => {
          console.error('❌ Error creating address:', err);
          alert('⚠️ Hiba történt a cím mentése során!');
        }
      });
    } else {
      // Use default address ID (1) for store pickup
      this.createOrderWithAddress(userId, 1);
    }
  }

  // Create order after address is ready
  private createOrderWithAddress(userId: number, addressId: number): void {
    // Prepare order data
    const orderData = {
      userId: userId,
      addressId: addressId,
      totalPrice: this.getTotal(),
      status: 'pending',
      items: this.cartItems.map(item => ({
        productId: item.product.id,
        quantity: item.quantity,
        price: item.product.pPrice
      }))
    };

    console.log('📦 Creating order...', orderData);

    // Send to backend
    this.orderService.createOrder(orderData).subscribe({
      next: (response) => {
        console.log('✅ Order created:', response);
        
        const orderId = response.orderId || response.id || 'UNKNOWN';
        
        // Also save to localStorage for immediate display on profile page
        this.saveOrderToLocalStorage(orderId);
        
        // Clear cart
        this.cartService.clearCart();
        
        // Show success message
        alert('✅ Rendelés sikeresen leadva!\n\nRendelésszám: ' + orderId + '\n\nKöszönjük a vásárlást!');
        
        // Redirect to profile page
        this.router.navigate(['/profile']);
      },
      error: (err) => {
        console.error('❌ Error creating order:', err);
        alert('⚠️ Hiba történt a rendelés leadása során!\n\n' + (err.error?.message || err.message || 'Ismeretlen hiba'));
      }
    });
  }

  // Save order to localStorage as backup (for immediate display)
  private saveOrderToLocalStorage(orderId: any): void {
    const order = {
      id: orderId,
      date: new Date().toISOString(),
      status: 'Feldolgozás alatt',
      statusClass: 'status-processing',
      customerData: { ...this.customerData },
      deliveryAddress: { ...this.deliveryAddress },
      deliveryMethod: this.selectedDeliveryMethod,
      paymentMethod: this.selectedPaymentMethod,
      items: this.cartItems.map(item => ({
        productId: item.product.id,
        name: item.product.name,
        quantity: item.quantity,
        price: item.product.pPrice
      })),
      subtotal: this.getSubtotal(),
      deliveryPrice: this.getDeliveryPrice(),
      total: this.getTotal()
    };
    
    const savedOrders = localStorage.getItem('user_orders');
    let orders = savedOrders ? JSON.parse(savedOrders) : [];
    orders.push(order);
    localStorage.setItem('user_orders', JSON.stringify(orders));
    
    console.log('💾 Order also saved to localStorage for immediate display');
  }

  // Go back to cart
  goBackToCart(): void {
    this.router.navigate(['/cart']);
  }

  // Get product image
  getProductImage(product: any): string {
    return `http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products/${product.id}/images/1`;
  }
}