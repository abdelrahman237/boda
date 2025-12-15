import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie_model.dart';
import '../../customer/models/booking.dart';
import '../../providers/booking_provider.dart';

class SeatsViewScreen extends StatefulWidget {
  final Movie movie;
  final String selectedSlot;

  const SeatsViewScreen({
    super.key,
    required this.movie,
    required this.selectedSlot,
  });

  @override
  State<SeatsViewScreen> createState() => _SeatsViewScreenState();
}

class _SeatsViewScreenState extends State<SeatsViewScreen> {
  List<Booking> _currentBookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBookings();
  }

  Future<void> _fetchCurrentBookings() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    await bookingProvider.getBookings(
      widget.movie.id,
      widget.selectedSlot,
    );
    setState(() {
      _currentBookings = bookingProvider.currentBookings;
      _loading = false;
    });
  }

  bool _isSeatBooked(String seatId) {
    for (var booking in _currentBookings) {
      if (booking.seats.contains(seatId)) {
        return true;
      }
    }
    return false;
  }

  Widget _buildSeat(String seatId) {
    final isBooked = _isSeatBooked(seatId);

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isBooked ? Colors.grey.shade400 : Colors.white,
        border: Border.all(
          color: isBooked ? Colors.grey.shade600 : Colors.grey.shade400,
          width: 2,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: isBooked
          ? const Icon(Icons.person, color: Colors.white, size: 18)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("${widget.movie.title} - ${widget.selectedSlot}"),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade400,
                  Color.fromARGB(255, 149, 125, 173),
                ],
              ),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.indigo.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading seat availability...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.movie.title} - ${widget.selectedSlot}"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo.shade400,
                Color.fromARGB(255, 149, 125, 173),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loading = true;
              });
              _fetchCurrentBookings();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Booking Statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.purple.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Bookings',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentBookings.fold<int>(0, (sum, b) => sum + b.seats.length)} seats',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Customers',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentBookings.length}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Screen
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.symmetric(vertical: 16),
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       colors: [Colors.grey.shade800, Colors.grey.shade900],
              //     ),
              //     borderRadius: BorderRadius.circular(12),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.3),
              //         blurRadius: 10,
              //         offset: const Offset(0, 5),
              //       ),
              //     ],
              //   ),
              //   child: const Center(
              //     child: Text(
              //       "SCREEN",
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontWeight: FontWeight.bold,
              //         fontSize: 18,
              //         letterSpacing: 3,
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 40),

              // Seats Layout - بدون Expanded
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // الصفوف 4 الأولى: 5 كراسي يسار + 4 كراسي يمين
                    ...List.generate(4, (row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            // 5 كراسي على اليسار
                            Row(
                              children: List.generate(5, (col) {
                                final seatId = '$row-$col-L';
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: _buildSeat(seatId),
                                );
                              }),
                            ),
                            const SizedBox(width: 40),
                            // 4 كراسي على اليمين
                            Row(
                              children: List.generate(4, (col) {
                                final seatId = '$row-$col-R';
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: _buildSeat(seatId),
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    }),

                    // الصف الأخير: 11 كرسي متصل
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: List.generate(11, (col) {
                          final seatId = '4-$col';
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: _buildSeat(seatId),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Legend
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 2,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          margin: const EdgeInsets.only(right: 6),
                        ),
                        const Text(
                          "Available",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(width: 30),
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            border: Border.all(
                              color: Colors.grey.shade600,
                              width: 2,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const Text(
                          "Booked",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
