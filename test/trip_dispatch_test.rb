require_relative 'test_helper'

TEST_DATA_DIRECTORY = 'test/test_data'

describe "TripDispatcher class" do
  def build_test_dispatcher
    return RideShare::TripDispatcher.new(
      directory: TEST_DATA_DIRECTORY
    )
  end
  
  describe "Initializer" do
    it "is an instance of TripDispatcher" do
      dispatcher = build_test_dispatcher
      expect(dispatcher).must_be_kind_of RideShare::TripDispatcher
    end
    
    it "establishes the base data structures when instantiated" do
      dispatcher = build_test_dispatcher
      [:trips, :passengers, :drivers].each do |prop|
        expect(dispatcher).must_respond_to prop
      end
      
      expect(dispatcher.trips).must_be_kind_of Array
      expect(dispatcher.passengers).must_be_kind_of Array
      expect(dispatcher.drivers).must_be_kind_of Array
    end
    
    it "loads the development data by default" do
      trip_count = %x{wc -l 'support/trips.csv'}.split(' ').first.to_i - 1
      
      dispatcher = RideShare::TripDispatcher.new
      
      expect(dispatcher.trips.length).must_equal trip_count
    end
  end
  
  describe "passengers" do
    describe "find_passenger method" do
      before do
        @dispatcher = build_test_dispatcher
      end
      
      it "throws an argument error for a bad ID" do
        expect{ @dispatcher.find_passenger(0) }.must_raise ArgumentError
      end
      
      it "finds a passenger instance" do
        passenger = @dispatcher.find_passenger(2)
        expect(passenger).must_be_kind_of RideShare::Passenger
      end
    end
    
    describe "Passenger & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end
      
      it "accurately loads passenger information into passengers array" do
        first_passenger = @dispatcher.passengers.first
        last_passenger = @dispatcher.passengers.last
        
        expect(first_passenger.name).must_equal "Passenger 1"
        expect(first_passenger.id).must_equal 1
        expect(last_passenger.name).must_equal "Passenger 8"
        expect(last_passenger.id).must_equal 8
      end
      
      it "connects trips and passengers" do
        dispatcher = build_test_dispatcher
        dispatcher.trips.each do |trip|
          expect(trip.passenger).wont_be_nil
          expect(trip.passenger.id).must_equal trip.passenger_id
          expect(trip.passenger.trips).must_include trip
        end
      end
    end
  end
  
  describe "drivers" do
    describe "find_driver method" do
      before do
        @dispatcher = build_test_dispatcher
      end
      
      it "throws an argument error for a bad ID" do
        expect { @dispatcher.find_driver(0) }.must_raise ArgumentError
      end
      
      it "finds a driver instance" do
        driver = @dispatcher.find_driver(2)
        expect(driver).must_be_kind_of RideShare::Driver
      end
    end
    
    describe "Driver & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end
      
      it "accurately loads driver information into drivers array" do
        first_driver = @dispatcher.drivers.first
        last_driver = @dispatcher.drivers.last
        
        expect(first_driver.name).must_equal "Driver 1 (unavailable)"
        expect(first_driver.id).must_equal 1
        expect(first_driver.status).must_equal :UNAVAILABLE
        expect(last_driver.name).must_equal "Driver 8 (no trips)"
        expect(last_driver.id).must_equal 8
        expect(last_driver.status).must_equal :AVAILABLE
      end
      
      it "connects trips and drivers" do
        dispatcher = build_test_dispatcher
        dispatcher.trips.each do |trip|
          expect(trip.driver).wont_be_nil
          expect(trip.driver.id).must_equal trip.driver_id
          expect(trip.driver.trips).must_include trip
        end
      end
    end
  end
  
  describe "request trip method" do
    before do
      @dispatcher = build_test_dispatcher
    end
    
    it "returns an instance of trip" do
      expect(@dispatcher.request_trip(7)).must_be_kind_of RideShare::Trip
    end
    
    it "finds first available driver with no trips" do    
      # Confirms that test driver is available and doesn't have trips
      expect(@dispatcher.find_driver(3).trips).must_equal []
      expect(@dispatcher.find_driver(3).status).must_equal :AVAILABLE
      
      # Runs request_trip method
      expect(@dispatcher.request_trip(6).driver_id).must_equal 3
      
      # Confirms that test driver is now unavailable and trip has been added to trips array
      expect(@dispatcher.find_driver(3).status).must_equal :UNAVAILABLE
      expect(@dispatcher.find_driver(3).trips.first).must_be_kind_of RideShare::Trip
      expect(@dispatcher.find_driver(3).trips.length).must_equal 1
    end
    
    it "finds longest idle driver when all available drivers have at least one trip" do
      2.times do
        @dispatcher.request_trip(5)
      end
      
      expect(@dispatcher.request_trip(1).driver_id).must_equal 6
    end
    
    it "updates driver trip list" do
      expect(@dispatcher.find_driver(3).trips.length).must_equal 0
      
      @dispatcher.request_trip(3)
      expect(@dispatcher.find_driver(3).trips.length).must_equal 1
    end
    
    it "updates passenger trip list" do
      expect(@dispatcher.find_passenger(1).trips.length).must_equal 1
      
      @dispatcher.request_trip(1)
      expect(@dispatcher.find_passenger(1).trips.length).must_equal 2
    end
    
    it "raises an error when no drivers are available" do
      6.times do 
        @dispatcher.request_trip(2)
      end
      
      expect{ @dispatcher.request_trip(3) }.must_raise ArgumentError
    end
    
    it "will not return drivers with a status of available and trip end time of nil" do 
      # Connects all six available drivers with a trip
      6.times do 
        @dispatcher.request_trip(2)
      end
      
      # Adds new driver with in-progress trip but available status
      trip = RideShare::Trip.new(
        id: 123,
        driver_id: 11,
        passenger_id: 7,
        start_time: Time.parse("2018-08-16 15:04:00 -0700"),
        end_time: nil,
        cost: 8,
        rating: 1
      )
      @dispatcher.drivers << RideShare::Driver.new(
        id: 11,
        name: "Driver 11",
        vin: "1B6CF40K1J3Y74UYZ",
        status: :AVAILABLE,
        trips: [trip]
      )
      
      expect{ @dispatcher.request_trip(3) }.must_raise ArgumentError
    end
  end
end
