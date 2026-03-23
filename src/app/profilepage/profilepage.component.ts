import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { ProfileService, Address } from '../services/profile.service';
import { FavoritesService, FavoriteProduct } from '../services/favorites.service';
import { CartService } from '../services/cart.service';
import { OrderService } from '../services/order.service';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { CommonModule } from '@angular/common';
import { PhoneValidator } from '../phone-validator';

@Component({
  selector: 'app-profilepage',
  standalone: true,
  imports: [HeaderComponent, FooterComponent, ReactiveFormsModule, CommonModule],
  templateUrl: './profilepage.component.html',
  styleUrls: ['./profilepage.component.css']
})
export class ProfilepageComponent implements OnInit {
  activeTab: string = 'fiokkezeles';
  
  // Formok inicializálása a konstruktorban - SOHA nem lesz undefined!
  customerDataForm: FormGroup;
  passwordForm: FormGroup;
  deliveryDataForm: FormGroup;

  userData: any = null;
  
  addresses: Address[] = [];
  selectedAddressId: number | null = null;
  isAddingNewAddress: boolean = false;
  
  isUpdatingProfile: boolean = false;
  isChangingPassword: boolean = false;

  showOldPassword: boolean = false;
  showNewPassword: boolean = false;
  showConfirmPassword: boolean = false;

  isOrdersModalOpen: boolean = false;
  isFavoritesModalOpen: boolean = false;
  
  favorites: FavoriteProduct[] = [];
  loadingFavorites: boolean = false;
  
  showSuccessMessage: boolean = false;
  successMessage: string = '';
  showErrorMessage: boolean = false;
  errorMessage: string = '';

  orders: any[] = [];

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private authService: AuthService,
    private profileService: ProfileService,
    private favoritesService: FavoritesService,
    private cartService: CartService,
    private orderService: OrderService
  ) {
    // FONTOS: Formok létrehozása RÖGTÖN a konstruktorban!
    this.customerDataForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      vezetekNev: ['', Validators.required],
      keresztNev: ['', Validators.required]
    });

    this.passwordForm = this.fb.group({
      regiJelszo: ['', Validators.required],
      ujJelszo: ['', [Validators.required, Validators.minLength(8)]],
      ujJelszoMegerosites: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });

    this.deliveryDataForm = this.fb.group({
      orszag: ['', Validators.required],
      iranyitoszam: ['', Validators.required],
      varos: ['', Validators.required],
      utcaHazszam: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      telefonszam: ['', Validators.required]
    });
  }

  ngOnInit(): void {
    this.loadUserData();
    this.loadAddresses();
    this.loadFavorites();
    this.loadOrders();
  }

  loadUserData(): void {
    console.log('👤 Loading user data...');
    
    const token = localStorage.getItem('JWT');
    if (!token) {
      console.error('❌ No JWT token - redirecting to login');
      this.router.navigate(['/login']);
      return;
    }

    this.profileService.getUserProfile().subscribe({
      next: (profile) => {
        if (profile) {
          console.log('✅ Profile loaded from backend:', profile);
          
          this.userData = {
            id: profile.id,
            username: profile.username,
            email: profile.email,
            role: profile.role,
            telefonszam: profile.phone || '',
            teljesnev: profile.teljesnev || '',
            vezetekNev: profile.teljesnev ? profile.teljesnev.split(' ')[0] : '',
            keresztNev: profile.teljesnev ? profile.teljesnev.split(' ').slice(1).join(' ') : '',
            cim: { orszag: '', iranyitoszam: '', varos: '', utcaHazszam: '' }
          };
          
          this.updateFormsWithData();
        } else {
          console.warn('⚠️ Backend returned null - using fallback');
          this.loadUserDataFallback();
        }
      },
      error: (err) => {
        console.error('❌ Error loading profile:', err);
        this.loadUserDataFallback();
      }
    });
  }

  loadUserDataFallback(): void {
    const currentUser = this.authService.getCurrentUser();
    
    if (currentUser) {
      const savedProfile = localStorage.getItem('currentUser');
      
      if (savedProfile) {
        this.userData = JSON.parse(savedProfile);
      } else {
        this.userData = {
          email: currentUser.email,
          username: currentUser.username,
          role: currentUser.role,
          telefonszam: '',
          vezetekNev: '',
          keresztNev: '',
          cim: { orszag: '', iranyitoszam: '', varos: '', utcaHazszam: '' }
        };
      }
      
      this.updateFormsWithData();
    } else {
      this.router.navigate(['/login']);
    }
  }

  updateFormsWithData(): void {
    if (this.userData) {
      this.customerDataForm.patchValue({
        email: this.userData.email || '',
        vezetekNev: this.userData.vezetekNev || '',
        keresztNev: this.userData.keresztNev || ''
      });

      this.deliveryDataForm.patchValue({
        email: this.userData.email || '',
        telefonszam: this.userData.telefonszam || ''
      });
    }
  }

  loadFavorites(): void {
    this.loadingFavorites = true;
    
    this.favoritesService.favorites$.subscribe({
      next: (favorites) => {
        this.favorites = favorites;
        this.loadingFavorites = false;
        console.log('✅ Favorites loaded:', this.favorites.length, 'db');
      },
      error: (err) => {
        console.error('❌ Error loading favorites:', err);
        this.loadingFavorites = false;
      }
    });
    
    this.favoritesService.refresh();
  }

  loadOrders(): void {
    this.orderService.getUserOrders().subscribe({
      next: (orders) => {
        console.log('📦 Orders from backend:', orders);
        
        const orderMap = new Map();
        
        orders.forEach((item: any) => {
          const orderId = item.order_id;
          
          if (!orderMap.has(orderId)) {
            orderMap.set(orderId, {
              id: orderId,
              date: item.created_at,
              status: this.mapOrderStatus(item.status),
              statusClass: this.getStatusClass(item.status),
              total: item.total_price,
              items: []
            });
          }
          
          orderMap.get(orderId).items.push({
            name: item.product_name,
            productName: item.product_name,
            quantity: item.quantity,
            price: item.product_price || 0,
            imageUrl: item.image_url
          });
        });
        
        this.orders = Array.from(orderMap.values());
        console.log('✅ Orders loaded:', this.orders.length, 'db');
      },
      error: (err) => {
        console.error('❌ Error loading orders:', err);
        this.orders = [];
      }
    });
  }
  
  private mapOrderStatus(status: string): string {
    const statusMap: { [key: string]: string } = {
      'pending': 'Feldolgozás alatt',
      'processing': 'Feldolgozás alatt',
      'shipping': 'Szállítás alatt',
      'delivered': 'Kézbesítve',
      'cancelled': 'Törölve'
    };
    return statusMap[status?.toLowerCase()] || status || 'Ismeretlen';
  }
  
  private getStatusClass(status: string): string {
    const classMap: { [key: string]: string } = {
      'pending': 'status-processing',
      'processing': 'status-processing',
      'shipping': 'status-shipping',
      'delivered': 'status-delivered',
      'cancelled': 'status-cancelled'
    };
    return classMap[status?.toLowerCase()] || 'status-processing';
  }

  passwordMatchValidator(group: FormGroup): { [key: string]: boolean } | null {
    const newPassword = group.get('ujJelszo')?.value;
    const confirmPassword = group.get('ujJelszoMegerosites')?.value;
    
    if (newPassword && confirmPassword && newPassword !== confirmPassword) {
      return { 'passwordMismatch': true };
    }
    return null;
  }

  setActiveTab(tab: string): void {
    this.activeTab = tab;
  }

  togglePasswordVisibility(field: string): void {
    switch (field) {
      case 'old':
        this.showOldPassword = !this.showOldPassword;
        break;
      case 'new':
        this.showNewPassword = !this.showNewPassword;
        break;
      case 'confirm':
        this.showConfirmPassword = !this.showConfirmPassword;
        break;
    }
  }

  // Phone input handler - használja a PhoneValidator.formatAsTyping-ot
  onPhoneInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const formatted = PhoneValidator.formatAsTyping(input.value);
    this.deliveryDataForm.patchValue({ telefonszam: formatted }, { emitEvent: false });
    input.value = formatted;
  }

  onSubmit(): void {
    this.isUpdatingProfile = true;
    
    this.userData.email = this.customerDataForm.value.email;
    this.userData.vezetekNev = this.customerDataForm.value.vezetekNev;
    this.userData.keresztNev = this.customerDataForm.value.keresztNev;
    this.userData.telefonszam = this.deliveryDataForm.value.telefonszam;
    this.userData.teljesnev = `${this.userData.vezetekNev} ${this.userData.keresztNev}`.trim();
    this.userData.cim = {
      orszag: this.deliveryDataForm.value.orszag,
      iranyitoszam: this.deliveryDataForm.value.iranyitoszam,
      varos: this.deliveryDataForm.value.varos,
      utcaHazszam: this.deliveryDataForm.value.utcaHazszam
    };

    const profileData = {
      username: this.userData.username,
      teljesnev: this.userData.teljesnev,
      email: this.userData.email,
      phone: this.userData.telefonszam
    };

    this.profileService.updateUserProfile(profileData).subscribe({
      next: (success) => {
        if (success) {
          this.showSuccess('Profil sikeresen frissítve!');
          this.saveDeliveryAddress();
        } else {
          this.showError('Nem sikerült frissíteni a profilt!');
        }
        this.isUpdatingProfile = false;
      },
      error: (err) => {
        console.error('Error updating profile:', err);
        this.showError('Hiba történt a mentés során!');
        this.isUpdatingProfile = false;
      }
    });
  }

  onPasswordChange(): void {
    if (this.passwordForm.invalid) {
      if (this.passwordForm.errors?.['passwordMismatch']) {
        this.showError('A két jelszó nem egyezik!');
      } else {
        this.showError('Kérjük, töltsd ki az összes mezőt!');
      }
      return;
    }

    this.isChangingPassword = true;
    
    setTimeout(() => {
      this.showSuccess('Jelszó sikeresen megváltoztatva!');
      this.passwordForm.reset();
      this.isChangingPassword = false;
    }, 1000);
  }

  resetChanges(): void {
    this.updateFormsWithData();
    this.showSuccess('Változások visszaállítva!');
  }

  getFullName(): string {
    if (this.userData?.teljesnev) {
      return this.userData.teljesnev;
    }
    const vezetek = this.userData?.vezetekNev || '';
    const kereszt = this.userData?.keresztNev || '';
    const fullName = `${vezetek} ${kereszt}`.trim();
    return fullName || '-';
  }

  isAdmin(): boolean {
    return this.userData?.role === 'admin';
  }

  goToAdminPage(): void {
    this.router.navigate(['/adminpage']);
  }

  // ==================== MODALS ====================

  openOrdersModal(): void {
    this.isOrdersModalOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeOrdersModal(): void {
    this.isOrdersModalOpen = false;
    document.body.style.overflow = 'auto';
  }

  openFavoritesModal(): void {
    this.isFavoritesModalOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeFavoritesModal(): void {
    this.isFavoritesModalOpen = false;
    document.body.style.overflow = 'auto';
  }

  removeFavorite(productId: number): void {
    this.favoritesService.removeFavorite(productId).subscribe({
      next: (response) => {
        if (response.success) {
          this.loadFavorites();
          this.showSuccess('Termék eltávolítva a kedvencekből!');
        }
      },
      error: (err) => {
        console.error('Error:', err);
      }
    });
  }

  addFavoriteToCart(favorite: FavoriteProduct): void {
    if (!this.cartService.isLoggedIn()) {
      this.showError('Be kell jelentkezned!');
      this.router.navigate(['/login']);
      return;
    }

    const product: any = {
      id: favorite.id,
      name: favorite.name,
      price: favorite.price,
      pPrice: favorite.pPrice,
      stock: favorite.stock,
      imageUrl: favorite.imageUrl,
      categoryId: { id: favorite.categoryId, name: favorite.categoryName },
      brandId: { id: favorite.brandId, name: favorite.brandName },
      description: favorite.description
    };

    const success = this.cartService.addToCart(product, 1);
    if (success) {
      this.showSuccess('Termék hozzáadva a kosárhoz!');
    }
  }

  // ==================== HELPER METHODS ====================

  getProductImageUrl(favorite: FavoriteProduct): string {
    return `http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products/${favorite.id}/images/1`;
  }

  formatPrice(price: number | undefined | null): string {
    if (price === null || price === undefined || isNaN(price)) {
      return '0 Ft';
    }
    return Math.round(price).toLocaleString('hu-HU') + ' Ft';
  }

  formatOrderDate(dateString: string): string {
    if (!dateString) return '-';
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}.${month}.${day}.`;
  }

  isInStock(favorite: FavoriteProduct): boolean {
    return favorite.stock > 0;
  }

  // ==================== ADDRESS MANAGEMENT ====================

  loadAddresses(): void {
    console.log('🏠 Loading addresses from backend...');
    this.profileService.getAddresses().subscribe({
      next: (addresses) => {
        this.addresses = addresses;
        console.log('✅ Addresses loaded:', addresses.length);
        
        const defaultAddress = addresses.find(addr => addr.isDefault);
        if (defaultAddress) {
          this.selectedAddressId = defaultAddress.id;
          this.populateDeliveryForm(defaultAddress);
        } else if (addresses.length > 0) {
          this.selectedAddressId = addresses[0].id;
          this.populateDeliveryForm(addresses[0]);
        }
      },
      error: (err) => {
        console.error('❌ Error loading addresses:', err);
      }
    });
  }

  populateDeliveryForm(address: Address): void {
    this.deliveryDataForm.patchValue({
      orszag: address.country,
      iranyitoszam: address.postalCode,
      varos: address.city,
      utcaHazszam: address.street,
      telefonszam: this.userData?.telefonszam || ''
    });
  }

  onAddressSelect(addressId: number): void {
    this.selectedAddressId = addressId;
    const address = this.addresses.find(addr => addr.id === addressId);
    if (address) {
      this.populateDeliveryForm(address);
    }
  }

  saveDeliveryAddress(): void {
    const hasAddressData = 
      this.deliveryDataForm.value.orszag || 
      this.deliveryDataForm.value.iranyitoszam ||
      this.deliveryDataForm.value.varos ||
      this.deliveryDataForm.value.utcaHazszam;

    if (!hasAddressData) {
      console.log('⚠️ No address data to save - skipping');
      return;
    }

    const addressData = {
      street: this.deliveryDataForm.value.utcaHazszam || '',
      city: this.deliveryDataForm.value.varos || '',
      postalCode: this.deliveryDataForm.value.iranyitoszam || '',
      country: this.deliveryDataForm.value.orszag || 'Magyarország',
      isDefault: this.addresses.length === 0
    };

    console.log('💾 Saving address:', addressData);

    if (this.isAddingNewAddress || this.selectedAddressId === null) {
      this.profileService.addAddress(addressData).subscribe({
        next: (success) => {
          if (success) {
            console.log('✅ Cím hozzáadva!');
            this.loadAddresses();
            this.isAddingNewAddress = false;
          }
        },
        error: (err) => console.error('❌ Error adding address:', err)
      });
    } else {
      this.profileService.updateAddress(this.selectedAddressId, addressData).subscribe({
        next: (success) => {
          if (success) {
            console.log('✅ Cím frissítve!');
            this.loadAddresses();
          }
        },
        error: (err) => console.error('❌ Error updating address:', err)
      });
    }
  }

  deleteAddress(addressId: number): void {
    this.profileService.deleteAddress(addressId).subscribe({
      next: (success) => {
        if (success) {
          this.showSuccess('Cím sikeresen törölve!');
          this.loadAddresses();
          if (this.selectedAddressId === addressId) {
            this.selectedAddressId = null;
          }
        } else {
          this.showError('Nem sikerült törölni a címet!');
        }
      },
      error: (err) => {
        console.error('❌ Error deleting address:', err);
        this.showError('Hiba történt a törlés során!');
      }
    });
  }

  setAsDefaultAddress(addressId: number): void {
    this.profileService.setDefaultAddress(addressId).subscribe({
      next: (success) => {
        if (success) {
          this.showSuccess('Alapértelmezett cím beállítva!');
          this.loadAddresses();
        } else {
          this.showError('Nem sikerült beállítani!');
        }
      },
      error: (err) => {
        console.error('❌ Error setting default:', err);
        this.showError('Hiba történt!');
      }
    });
  }

  addNewAddress(): void {
    this.isAddingNewAddress = true;
    this.selectedAddressId = null;
    this.deliveryDataForm.patchValue({
      orszag: '',
      iranyitoszam: '',
      varos: '',
      utcaHazszam: '',
      telefonszam: this.userData?.telefonszam || ''
    });
  }

  cancelNewAddress(): void {
    this.isAddingNewAddress = false;
    if (this.addresses.length > 0) {
      const defaultAddr = this.addresses.find(a => a.isDefault) || this.addresses[0];
      this.selectedAddressId = defaultAddr.id;
      this.populateDeliveryForm(defaultAddr);
    }
  }

  logout(): void {
    this.authService.logout();
    this.favoritesService.clearFavorites();
    this.router.navigate(['/mainpage']);
  }
  
  showSuccess(message: string): void {
    this.successMessage = message;
    this.showSuccessMessage = true;
    setTimeout(() => {
      this.showSuccessMessage = false;
    }, 2000);
  }
  
  showError(message: string): void {
    this.errorMessage = message;
    this.showErrorMessage = true;
    setTimeout(() => {
      this.showErrorMessage = false;
    }, 3000);
  }
}