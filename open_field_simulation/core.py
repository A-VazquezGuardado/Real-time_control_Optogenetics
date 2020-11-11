import numpy as np
import math
import string
import random


class Environment:
    """
    Class to represent rectangular environment

    Attributes
    ----------
    width: (int) width of arena in mm
    height: (int) height of arena in mm
    mice: (dict) {'mouse_id': {'x': [], 'y': []}} contains current position
          (perimeter) of all mice in the arena.

    Methods
    -------
    register_mouse(ID)
        register a new mouse to the environment
    store_mouse_position(ID, x, y)
        store current position of a given mouse
    in_environment(mouse_perimeter)
        determines if mouse is in the environment
    intersects(list_1, list_2)
        determines whether two lists of points overlap
    space_occupied(ID, mouse_perimeter_x, mouse_perimeter_y)
        determines whether a given space is occupied
    valid_move(mouse_perimeter_x, mouse_perimeter_y, ID)
        determine if a proposed move is valid
    """
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.mice = {}

    def register_mouse(self, ID):
        """
        register a new mouse in the environment

        Inputs
        ------
        ID: (str) mouse ID

        Returns
        -------
        bool whether the registration was successful
        """
        if ID not in self.mice.keys():
            self.mice[ID] = {'x': [], 'y': []}
            return True
        else:
            return False

    def store_mouse_position(self, ID, x_points, y_points):
        """
        store current position of mouse

        Inputs
        ------
        ID: (str) mouse ID
        x_points: (list of floats) points along mouse perimeter
        y_points: (list of floats) points along mouse perimeter

        Returns
        -------
        """
        self.mice[ID]['x'] = x_points
        self.mice[ID]['y'] = y_points

    def in_environment(self, x_points, y_points):
        """
        check whether the passed points are in the environment

        Inputs
        ------
        x_points: (list of floats) points along mouse perimeter
        y_points: (list of floats) points along mouse perimeter

        Returns
        -------
        (bool) whether the points are in the environment or not
        """
        x_in_env = [point > 0 and point < self.width for point in x_points]
        y_in_env = [point > 0 and point < self.height for point in y_points]

        return all(x_in_env + y_in_env)

    def intersects(self, list_1, list_2):
        """
        check whether the points in the two lists overlap

        Inputs
        ------
        list_1: (list of floats) points along mouse perimeter
        list_2: (list of floats) points along mouse perimeter

        Returns
        -------
        (bool) whether the points overlap
        """
        points_greater = []
        points_less_than = []

        for point in list_1:
            greater = [point > x for x in list_2]
            less_than = [point < x for x in list_2]

            points_greater.append(any(greater))
            points_less_than.append(any(less_than))

        return any(points_greater) and any(less_than)

    def space_occupied(self, ID, mouse_perimeter_x, mouse_perimeter_y):
        """
        determine if the passed space is occupied

        Inputs
        ------
        ID: (str) mouse ID
        mouse_perimeter_x: (list of floats) x points along mouse perimeter
        mouse_perimeter_y: (list of floats) y points along mouse perimeter

        Returns
        -------
        (bool) whether the space is occupied
        """
        is_occupied = []

        other_mice = list(self.mice.keys())
        other_mice.remove(ID)

        if other_mice:
            for mouse in other_mice:
                x_within = self.intersects(
                    mouse_perimeter_x, self.mice[mouse]['x'])
                y_within = self.intersects(
                    mouse_perimeter_x, self.mice[mouse]['y'])

                is_occupied.append(x_within and y_within)

            return any(is_occupied)
        else:
            return False

    def valid_move(self, mouse_perimeter_x, mouse_perimeter_y, ID):
        """"
        determine if a proposed move is valid

        Inputs
        ------
        mouse_perimeter_x: (list of floats) x points along mouse perimeter
        mouse_perimeter_y: (list of floats) y points along mouse perimeter
        ID: (str) mouse ID

        Returns
        -------
        (bool) whether the proposed move is valid

        """
        return (self.in_environment(mouse_perimeter_x, mouse_perimeter_y)
                and not self.space_occupied(
                                ID, mouse_perimeter_x, mouse_perimeter_y))


class Mouse:
    """
    Class to represent a mouse. Modeled as a circle for now.

    Attributes
    ----------
    avg_speed: (int) mouse average speed (mm/ms) default 0.09
    speed_std: (int) mouse speed standard deviation (mm/ms) default 0.06
    major_axis: (int) major axis of ellipse representing mouse (mm) default 60
    minor_axis: (int) minor axis of ellipse representing mouse (mm) default 30
    mouse_id: (str) unique random str for each mouse
    environment: (Environment) environment instance
    x_center: (float) x position of mouse center
    y_center: (float) y position of mouse center
    x_center_history: (list of floats) past x center positions
    y_center_history: (list of floats) past y center positions
    x_perimeter_history: (list of floats) past x perimeter positions
    y_perimeter_history: (list of floats) past y perimeter positions
    n_mice: (int) number of mice in arena
    order_placed: (int) the order this mouse was placed in arena (1st, 2nd...)

    Methods
    -------
    generate_id()
        generate unique mouse id

    initialize_position(n_mice, order_placed)
        intitialize mouse position

    register_to_env()
        register mouse to environment

    get_position()
        returns the position of the mouse's center

    set_position(x, y)
        sets the position of the mouse's center

    get_mouse_perimeter(center_x, center_y, rotation_angle):
        get points along mouse perimeter

    get_speed()
        samples mouse speed from gaussian centered at avg_speed with std given
        by speed_std

    get_heading_direction()
        get mouse heading direction

    get_rotation_angle(hit_wall)
        samples rotation angle from uniform (first move or if hit wall) or
        gaussian distribution

    compute_new_center(duration, hit_wall)
        compute new mouse center position

    move(movement_duration)
        move the mouse

    update_position_history(mouse_perimeter_x, mouse_perimeter_y)
        update center and perimeter history lists

    get_position_history()
        return center and perimeter history lists
    """
    def __init__(self, environment, n_mice, order_placed, avg_speed=None,
                 speed_std=None, major_axis=None, minor_axis=None):
        if not avg_speed:
            avg_speed = 0.09
        if not speed_std:
            speed_std = 0.06
        if not major_axis:
            major_axis = 60
        if not minor_axis:
            minor_axis = 30

        self.avg_speed = avg_speed
        self.speed_std = speed_std
        self.major_axis = major_axis
        self.minor_axis = minor_axis
        self.ID = ''
        self.environment = environment

        self.x_center_history = []
        self.y_center_history = []
        self.x_perimeter_history = []
        self.y_perimeter_history = []

        self.initialize_position(n_mice, order_placed)
        self.register_to_env()

    def generate_id(self):
        """
        generate mouse ID
        """
        id_length = 10
        self.ID = ''.join(random.choices(string.ascii_uppercase, k=id_length))

    def initialize_position(self, n_mice, order_placed):
        """
        initialize mouse position. Mice are spaced equidistantly across the
        environment width.

        Inputs
        -------
        n_mice: (int) number of mice in environment
        order_placed: (int) the order this mouse was placed in environment
                           (1st, 2nd...)
        """
        if n_mice == 1:
            self.x_center = self.environment.width/2
            self.y_center = self.environment.height/2
        else:
            # space mice equidistantly across the width of the environment
            all_positions_x = np.linspace(0, self.environment.width, n_mice+2)
            all_positions_y = np.linspace(0, self.environment.height, n_mice+2)

            self.x_center = all_positions_x[order_placed+1]
            self.y_center = all_positions_y[order_placed+1]

        rotation_angle = self.get_rotation_angle()
        x_perimeter, y_perimeter = self.get_mouse_perimeter(
            self.x_center, self.y_center, rotation_angle)

        self.update_position_history(x_perimeter, y_perimeter)

    def register_to_env(self):
        """
        register mouse to environment
        """
        successful = False
        while not successful:
            self.generate_id()
            successful = self.environment.register_mouse(self.ID)

    def get_position(self):
        """
        get coordinates of mouse's center

        Returns
        -------
        x_center: (float) current x position of mouse
        y_center: (float) current y position of mouse
        """
        return self.x_center, self.y_center

    def set_position(self, new_x, new_y):
        """
        set coordinates of mouse's center

        Inputs
        -------
        x_center: (float) current x position of mouse
        y_center: (float) current y position of mouse
        """
        self.x_center = new_x
        self.y_center = new_y

    def get_mouse_perimeter(self, center_x, center_y, rotation_angle):
        """
        get points along mouse perimeter

        Inputs
        ------
        center_x, center_y: (float) center of mouse
        rotation_angle: (float) angle in radians

        Returns
        -------
        mouse_perimeter_x: (list of floats) x points along mouse perimeter
        mouse_perimeter_y: (list of floats) y points along mouse perimeter
        """
        # discretize mouse perimeter at origin
        x = [(self.major_axis/2)*math.cos(i)
             for i in np.arange(0, 2*math.pi, 0.05)]
        y = [(self.minor_axis/2)*math.sin(i)
             for i in np.arange(0, 2*math.pi, 0.05)]

        mouse_perimeter_x, mouse_perimeter_y = [], []

        # rotate mouse perimeter and move it to (center_x, center_y)
        for i in range(len(x)):
            mouse_perimeter_x.append(
                x[i]*math.cos(rotation_angle)-y[i]*math.sin(rotation_angle)
                + center_x)
            mouse_perimeter_y.append(
                y[i]*math.cos(rotation_angle)+x[i]*math.sin(rotation_angle)
                + center_y)

        return mouse_perimeter_x, mouse_perimeter_y

    def get_speed(self):
        """
        samples mouse speed from gaussian centered at avg_speed with std given
        by speed_std

        Returns
        -------
        speed: (float) mm/ms
        """
        return np.random.default_rng().normal(
            self.avg_speed,
            self.speed_std,
            1)[0]

    def get_heading_direction(self):
        """
        get heading direction

        Returns
        heading_direction: (float) heading direction in radians
        """
        return math.atan2(
            (self.y_center_history[-2] - self.y_center_history[-1]),
            (self.x_center_history[-2] - self.x_center_history[-1])
        )

    def get_rotation_angle(self, hit_wall=False):
        """
        samples mouse's rotation angle from uniform(first move or hit wall) or
        from gaussian centered at previous heading drxn

        Inputs
        ------
        hit_wall: (bool) whether the previous movement attempt hit the wall

        Returns
        -------
        rotation_angle: (float) radians
        """
        if len(self.x_center_history) <= 1 or hit_wall:
            angle = np.random.default_rng().uniform(0, 2*math.pi, 1)[0]
            return angle

        elif not hit_wall:
            heading_direction = self.get_heading_direction()

            angle = np.random.default_rng().normal(
                heading_direction,
                math.pi/4,
                1
            )[0]

            return angle

    def compute_new_center(self, duration, hit_wall=False):
        """
        compute new mouse center position

        Inputs
        ------
        duration: (float) duration for movement in milliseconds
        hit_wall: (bool) whether the previous movement attempt hit the wall

        Returns
        -------
        new_x: (float) mouse's new x coordinate
        new_y: (float) mouse's new y coordinate
        rotation_angle: (float) rotation angle in radians
        """
        speed = self.get_speed()
        distance = speed*duration

        rotation_angle = self.get_rotation_angle(hit_wall)

        displacement_x = distance*math.cos(rotation_angle)
        displacement_y = distance*math.sin(rotation_angle)

        current_x, current_y = self.get_position()

        new_x = current_x + displacement_x
        new_y = current_y + displacement_y

        return new_x, new_y, rotation_angle

    def move(self, movement_duration):
        """
        move the mouse

        Inputs
        ------
        movement_duration: (float) duration for movement in milliseconds
        """
        new_x, new_y, rotation_angle = self.compute_new_center(
            movement_duration)

        mouse_perimeter_x, mouse_perimeter_y = self.get_mouse_perimeter(
            new_x, new_y, rotation_angle)

        while not self.environment.valid_move(
                mouse_perimeter_x, mouse_perimeter_y, self.ID):

            new_x, new_y, rotation_angle = self.compute_new_center(
                        movement_duration, hit_wall=True)
            mouse_perimeter_x, mouse_perimeter_y = self.get_mouse_perimeter(
                new_x, new_y, rotation_angle)

        self.set_position(new_x, new_y)
        self.update_position_history(mouse_perimeter_x, mouse_perimeter_y)
        self.environment.store_mouse_position(
            self.ID, mouse_perimeter_x, mouse_perimeter_y)

    def update_position_history(self, mouse_perimeter_x, mouse_perimeter_y):
        """
        update center and perimeter history lists

        Inputs
        ------
        mouse_perimeter_x: (list of floats) current x perimeter points
        mouse_perimeter_y: (list of floats) current y perimeter points
        """
        self.x_center_history.append(self.x_center)
        self.y_center_history.append(self.y_center)
        self.x_perimeter_history.append(mouse_perimeter_x)
        self.y_perimeter_history.append(mouse_perimeter_y)

    def get_position_history(self):
        """
        returns the center and perimeter position histories

        Returns
        -------
        x_center_history: (list of floats) past x center positions
        y_center_history: (list of floats) past y center positions
        x_perimeter_history: (list of floats) past x perimeter positions
        y_perimeter_history: (list of floats) past y perimeter positions
        """
        return (self.x_center_history, self.y_center_history,
                self.x_perimeter_history, self.y_perimeter_history)
