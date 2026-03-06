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
  styleUrl: './profilepage.component.css',
})
export class ProfilepageComponent implements OnInit {
  activeTab: string = 'fiokkezeles';
  
  customerDataForm!: FormGroup;
  passwordForm!: FormGroup;
  deliveryDataForm!: FormGroup;

  userData: any = null;
  
  // Addresses from backend
  addresses: Address[] = [];
  selectedAddressId: number | null = null;
  isAddingNewAddress: boolean = false;
  
  isUpdatingProfile: boolean = false;
  isChangingPassword: boolean = false;

  showOldPassword: boolean = false;
  showNewPassword: boolean = false;
  showConfirmPassword: boolean = false;

  // Rendeléseim modal
  isOrdersModalOpen: boolean = false;
  
  // Kedvencek modal
  isFavoritesModalOpen: boolean = false;
  
  // Kedvencek - VALÓDI ADATOK
  favorites: FavoriteProduct[] = [];
  loadingFavorites: boolean = false;
  
  // Notification states
  showSuccessMessage: boolean = false;
  successMessage: string = '';
  showErrorMessage: boolean = false;
  errorMessage: string = '';

  
  // Rendelések - VALÓDI ADATOK (mock adatok törölve!)
  orders: any[] = [];

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private authService: AuthService,
    private profileService: ProfileService,
    private favoritesService: FavoritesService,
    private cartService: CartService,
    private orderService: OrderService
  ) {}

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

    // Try to load from backend
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
          
          this.initializeForms();
        } else {
          console.warn('⚠️ Backend returned null - using fallback');
          this.loadUserDataFallback();
        }
      },
      error: (err) => {
        console.error('❌ Error loading profile:', err);
        console.warn('⚠️ Using fallback user data');
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
      
      this.initializeForms();
    } else {
      this.router.navigate(['/login']);
    }
  }

  // Kedvencek betöltése - PONTOSAN a service szerint
  loadFavorites(): void {
    this.loadingFavorites = true;
    
    // Subscribe to favorites observable from service
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
    
    // Trigger refresh from backend
    this.favoritesService.refresh();
  }

  // Rendelések betöltése - backend
  loadOrders(): void {
    this.orderService.getUserOrders().subscribe({
      next: (orders) => {
        console.log('📦 Orders from backend:', orders);
        
        // Group orders by order_id
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
          
          // Add item to order
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
  
  // Map backend status to Hungarian
  private mapOrderStatus(status: string): string {
    const statusMap: { [key: string]: string } = {
      'pending': 'Feldolgozás alatt',
      'processing': 'Feldolgozás alatt',
      'shipping': 'Szállítás alatt',
      'delivered': 'Kézbesítve',
      'cancelled': 'Törölve'
    };
    return statusMap[status.toLowerCase()] || status;
  }
  
  // Get CSS class for status
  private getStatusClass(status: string): string {
    const classMap: { [key: string]: string } = {
      'pending': 'status-processing',
      'processing': 'status-processing',
      'shipping': 'status-shipping',
      'delivered': 'status-delivered',
      'cancelled': 'status-cancelled'
    };
    return classMap[status.toLowerCase()] || 'status-processing';
  }

  initializeForms(): void {
    this.customerDataForm = this.fb.group({
      email: [this.userData?.email || '', [Validators.required, Validators.email]],
      vezetekNev: [this.userData?.vezetekNev || '', Validators.required],
      keresztNev: [this.userData?.keresztNev || '', Validators.required]
    });

    this.passwordForm = this.fb.group({
      regiJelszo: ['', Validators.required],
      ujJelszo: ['', [Validators.required, Validators.minLength(8)]],
      ujJelszoMegerosites: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });

    this.deliveryDataForm = this.fb.group({
      orszag: [this.userData?.cim?.orszag || '', Validators.required],
      iranyitoszam: [this.userData?.cim?.iranyitoszam || '', Validators.required],
      varos: [this.userData?.cim?.varos || '', Validators.required],
      utcaHazszam: [this.userData?.cim?.utcaHazszam || '', Validators.required],
      email: [this.userData?.email || '', [Validators.required, Validators.email]],
      telefonszam: [this.userData?.telefonszam || '', Validators.required]
    });
  }

  passwordMatchValidator(group: FormGroup): { [key: string]: boolean } | null {
    const newPassword = group.get('ujJelszo')?.value;
    const confirmPassword = group.get('ujJelszoMegerosites')?.value;
    return (newPassword !== confirmPassword) ? { passwordMismatch: true } : null;
  }

  togglePasswordVisibility(field: 'old' | 'new' | 'confirm'): void {
    if (field === 'old') this.showOldPassword = !this.showOldPassword;
    else if (field === 'new') this.showNewPassword = !this.showNewPassword;
    else this.showConfirmPassword = !this.showConfirmPassword;
  }

  getFullName(): string {
    return `${this.userData?.vezetekNev || ''} ${this.userData?.keresztNev || ''}`.trim();
  }

  getFullAddress(): string {
    if (!this.userData?.cim) return '';
    const { varos, iranyitoszam, utcaHazszam } = this.userData.cim;
    return `${varos || ''}, ${iranyitoszam || ''}, ${utcaHazszam || ''}`.replace(/(^,\s*|,\s*$)/g, '');
  }

  hasDeliveryData(): boolean {
    if (!this.userData?.cim) return false;
    const { orszag, iranyitoszam, varos, utcaHazszam } = this.userData.cim;
    return !!(orszag || iranyitoszam || varos || utcaHazszam);
  }

  setActiveTab(tab: string): void {
    this.activeTab = tab;
  }

  isAdmin(): boolean {
    const role = this.userData?.role;
    if (!role) return false;
    const roleLower = role.toString().toLowerCase();
    return roleLower === 'admin' || roleLower === 'administrator';
  }

  goToAdminPage(): void {
    this.router.navigate(['/adminpage']);
  }

  // Phone number input handler - auto-format as user types
  onPhoneInput(event: any): void {
    const input = event.target.value;
    this.deliveryDataForm.patchValue({
      telefonszam: PhoneValidator.formatAsTyping(input)
    });
  }

  onSubmit(): void {
    if (this.customerDataForm.valid) {
      const vezetekNev = this.customerDataForm.value.vezetekNev || '';
      const keresztNev = this.customerDataForm.value.keresztNev || '';
      const teljesnev = `${vezetekNev} ${keresztNev}`.trim();
      
      console.log('🔍 DEBUG - vezetekNev:', vezetekNev);
      console.log('🔍 DEBUG - keresztNev:', keresztNev);
      console.log('🔍 DEBUG - teljesnev:', teljesnev);
      
      const phone = this.deliveryDataForm.value.telefonszam || '';
      
      // Validate phone number
      if (phone && !PhoneValidator.isValid(phone)) {
        this.showError(PhoneValidator.getErrorMessage(phone));
        return;
      }
      
      const updatedData = {
        username: this.userData.username,
        teljesnev: teljesnev,
        email: this.customerDataForm.value.email,
        phone: phone
      };

      console.log('💾 Saving profile data:', updatedData);
      this.isUpdatingProfile = true;

      this.profileService.updateUserProfile(updatedData).subscribe({
        next: (success) => {
          if (success) {
            this.userData.email = updatedData.email;
            this.userData.teljesnev = updatedData.teljesnev;
            this.userData.telefonszam = updatedData.phone;
            this.userData.vezetekNev = vezetekNev;
            this.userData.keresztNev = keresztNev;
            
            // Update localStorage user object
            const currentUser = this.authService.getCurrentUser();
            if (currentUser) {
              currentUser.teljesnev = updatedData.teljesnev;
              currentUser.phone = updatedData.phone;
              currentUser.email = updatedData.email;
              localStorage.setItem('user', JSON.stringify(currentUser));
              console.log('✅ localStorage user updated:', currentUser);
            }
            
            // After profile saved, save address too
            console.log('💾 Now saving address...');
            this.saveDeliveryAddress();
            
            this.showSuccess('Változások sikeresen mentve!');
          } else {
            this.showError('Nem sikerült menteni a változásokat!');
          }
          this.isUpdatingProfile = false;
        },
        error: (error) => {
          console.error('❌ Update error:', error);
          this.isUpdatingProfile = false;
          
          if (error.status === 0 || error.name === 'HttpErrorResponse') {
            console.warn('⚠️ CORS error or backend not ready - saving locally');
            this.userData.email = updatedData.email;
            this.userData.teljesnev = updatedData.teljesnev;
            this.userData.telefonszam = updatedData.phone;
            this.userData.vezetekNev = vezetekNev;
            this.userData.keresztNev = keresztNev;
            this.showError('Backend nem elérhető - adatok ideiglenesen mentve!');
          } else if (error.status === 401) {
            this.showError('Érvénytelen token!');
            this.authService.logout();
            this.router.navigate(['/login']);
          } else {
            this.showError('Hiba történt a mentés során!');
          }
        }
      });
    } else {
      this.showError('Töltsd ki az összes kötelező mezőt!');
    }
  }

  onPasswordChange(): void {
    if (!this.passwordForm.valid) {
      this.showError('Töltsd ki az összes jelszó mezőt helyesen!');
      return;
    }

    const oldPassword = this.passwordForm.value.regiJelszo;
    const newPassword = this.passwordForm.value.ujJelszo;
    const confirmPassword = this.passwordForm.value.ujJelszoMegerosites;

    if (newPassword !== confirmPassword) {
      this.showError('Az új jelszavak nem egyeznek!');
      return;
    }

    if (!this.authService.isLoggedIn()) {
      this.showError('Lejárt a munkamenet!');
      this.authService.logout();
      this.router.navigate(['/login']);
      return;
    }

    this.isChangingPassword = true;

    this.authService.changePassword(oldPassword, newPassword).subscribe({
      next: (response) => {
        this.isChangingPassword = false;
        this.showSuccess('Jelszó sikeresen megváltoztatva!');
        this.passwordForm.reset();
        this.showOldPassword = false;
        this.showNewPassword = false;
        this.showConfirmPassword = false;
      },
      error: (error) => {
        this.isChangingPassword = false;
        
        let errorMsg = '❌ Hiba történt!';
        
        if (error.status === 401) {
          errorMsg = '❌ A régi jelszó helytelen!';
        } else if (error.status === 400) {
          errorMsg = '❌ Gyenge jelszó!';
        }
        
        this.showError(errorMsg.replace('❌ ', ''));
      }
    });
  }

  resetChanges(): void {
    this.customerDataForm.patchValue({
      email: this.userData?.email || '',
      vezetekNev: this.userData?.vezetekNev || '',
      keresztNev: this.userData?.keresztNev || ''
    });

    this.passwordForm.reset();
    this.showOldPassword = false;
    this.showNewPassword = false;
    this.showConfirmPassword = false;

    this.deliveryDataForm.patchValue({
      orszag: this.userData?.cim?.orszag || '',
      iranyitoszam: this.userData?.cim?.iranyitoszam || '',
      varos: this.userData?.cim?.varos || '',
      utcaHazszam: this.userData?.cim?.utcaHazszam || '',
      email: this.userData?.email || '',
      telefonszam: this.userData?.telefonszam || ''
    });
    
    this.showSuccess('Változások visszaállítva!');
  }

  // Rendeléseim modal
  openOrdersModal(): void {
    this.loadOrders();
    this.isOrdersModalOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeOrdersModal(): void {
    this.isOrdersModalOpen = false;
    document.body.style.overflow = 'auto';
  }

  // Kedvencek modal
  openFavoritesModal(): void {
    this.loadFavorites();
    this.isFavoritesModalOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeFavoritesModal(): void {
    this.isFavoritesModalOpen = false;
    document.body.style.overflow = 'auto';
  }

  // Kedvenc eltávolítása - service.removeFavorite()
  removeFavorite(productId: number): void {

    this.favoritesService.removeFavorite(productId).subscribe({
      next: (response) => {
        if (response.success) {
          this.loadFavorites(); // Reload
          this.showSuccess('Termék eltávolítva a kedvencekből!');
        }
      },
      error: (err) => {
        console.error('Error:', err);
      }
    });
  }

  // Kosárba helyezés
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
      categoryId: {
        id: favorite.categoryId,
        name: favorite.categoryName
      },
      brandId: {
        id: favorite.brandId,
        name: favorite.brandName
      },
      description: favorite.description
    };

    const success = this.cartService.addToCart(product, 1);
    if (success) {
      this.showSuccess('Termék hozzáadva a kosárhoz!');
    }
  }

  // Helper methods
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
    // Check if address fields are filled
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
          } else {
            console.error('❌ Nem sikerült hozzáadni a címet!');
          }
        },
        error: (err) => {
          console.error('❌ Error adding address:', err);
        }
      });
    } else {
      this.profileService.updateAddress(this.selectedAddressId, addressData).subscribe({
        next: (success) => {
          if (success) {
            console.log('✅ Cím frissítve!');
            this.loadAddresses();
          } else {
            console.error('❌ Nem sikerült frissíteni a címet!');
          }
        },
        error: (err) => {
          console.error('❌ Error updating address:', err);
        }
      });
    }
  }

  deleteAddress(addressId: number): void {
    if (!confirm('Biztosan törölni szeretnéd ezt a címet?')) {
      return;
    }

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
    this.deliveryDataForm.reset({
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
    this.favoritesService.clearFavorites();
    this.router.navigate(['/mainpage']);
  }
  
  // Notification helper methods
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